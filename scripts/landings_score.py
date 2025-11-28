# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# pylint: disable=C0330, g-bad-import-order, g-multiple-import

"""Processes landing pages to find relevance between ads and keywords."""

import os

import garf_core
from garf_executors.bq_executor import BigQueryExecutor
from garf_executors.entrypoints import utils as garf_utils
from garf_io import reader, writer
from media_tagging import MediaTaggingRequest, MediaTaggingService, repositories
from media_tagging.taggers.llm.gemini.tagging_strategies import (
  _parse_json as parse_json,
)

logger = garf_utils.init_logging(name='landings')

PROMPT_TEMPLATE = """
Given the following keywords and ads give me score of how the landing page
is relevant to them.
Keywords: {keywords}
Ads: {ads}
Landing: {landing_url}
Format the response as a JSON object with the following schema:
{{
  "score": "<Number from 1 to 10 where 1 means that landing page is completely
  irrelevant to and 10 is completely relevant>"
}}
"""


def process_landing(
  tagging_service: MediaTaggingService,
  landing_url: str,
  ads: list[str],
  keywords: list[str],
) -> int:
  """Processes a single landing to find its relevance to ads and keywords.

  Args:
    tagging_service: Service for processing ads, landings, keywords.
    landing_url: Url to process.
    ads: All ads associated with a single campaign.
    keywords: All keywords associated with a single campaign.

  Returns:
    Score that shows how relevant landing page to ads & keywords.
  """
  prompt = build_prompt(landing_url, ads, keywords)
  result = tagging_service.describe_media(
    MediaTaggingRequest(
      tagger_type='gemini',
      media_paths=[landing_url],
      tagging_options={
        'model_name': 'gemini-2.5-flash',
        'custom_prompt': prompt,
      },
      media_type='WEBPAGE',
    )
  )
  try:
    score = parse_json(result.results[0].content.text).get('score')
  except Exception:
    score = -1
  return score


def build_prompt(landing_url: str, ads: list[str], keywords: list[str]) -> str:
  """Builds prompt based on landing pages, ads and keywords."""
  ads = '|'.join(list(set(ads)))
  keywords = '|'.join(list(set(keywords)))
  return PROMPT_TEMPLATE.format(
    landing_url=landing_url, ads=ads, keywords=keywords
  )


def main():
  tagging_service = MediaTaggingService(
    repositories.SqlAlchemyTaggingResultsRepository(
      db_url=os.getenv('ARBA_DB_URI')
    )
  )

  bq_executor = BigQueryExecutor()
  query = reader.FileReader().read(query_path='./landings.sql')
  query = query.format(dataset='arba')
  landings = bq_executor.execute(
    query=query,
    title='landings',
  )

  data = []
  max_processed = 50
  bq_writer = writer.create_writer('bq', dataset='arba')
  for landing, items in landings.to_dict('url').items():
    for campaign in items:
      if max_processed < 0:
        report = garf_core.GarfReport(
          results=data, column_names=['campaign_id', 'url', 'relevance_score']
        )
        bq_writer.write(report, 'landing_page_relevance')
        return
      campaign_id = campaign.get('campaign_id')
      logger.info('working on campaign %s for landing %s', campaign_id, landing)
      logger.info('%d iterations left...', max_processed)

      score = process_landing(
        tagging_service,
        landing,
        ads=campaign.get('ads'),
        keywords=campaign.get('keywords'),
      )
      data.append([campaign_id, landing, score])
      max_processed = max_processed - 1
  report = garf_core.GarfReport(
    results=data, column_names=['campaign_id', 'url', 'relevance_score']
  )
  bq_writer.write(report, 'landing_page_relevance')
  return


if __name__ == '__main__':
  main()
