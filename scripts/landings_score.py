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

import json
import logging
import os

import pydantic
import typer
from garf.core.report import GarfReport
from garf.executors.bq_executor import BigQueryExecutor
from garf.executors.entrypoints import utils as garf_utils
from garf.io import reader, writer
from media_tagging import MediaTaggingRequest, MediaTaggingService, repositories
from typing_extensions import Annotated

logger = logging.getLogger('arba.scripts.landings_score')

app = typer.Typer()

PROMPT_TEMPLATE = """
Given the following keywords and ads give me score of how the landing page
is relevant to them.
Keywords: {keywords}
Ads: {ads}
Landing: {landing_url}
Format the response as a JSON object with the following schema:
{{
  "score": "<Number from 1 to 10 where 1 means that landing page is completely
  irrelevant to and 10 is completely relevant>",
  "reason": "reason behind assigning a particular relevance score"
}}
"""


class ScoreSchema(pydantic.BaseModel):
  score: int = pydantic.Field(
    description='relevance score between webpage, ad copy and search keywords'
  )
  reason: str = pydantic.Field(
    description='reason behind assigning a particular relevance score'
  )


def process_landing(
  tagging_service: MediaTaggingService,
  landing_url: str,
  ads: list[str],
  keywords: list[str],
) -> dict[str, str | int]:
  """Processes a single landing to find its relevance to ads and keywords.

  Args:
    tagging_service: Service for processing ads, landings, keywords.
    landing_url: Url to process.
    ads: All ads associated with a single ad_group.
    keywords: All keywords associated with a single ad_group.

  Returns:
    Score that shows how relevant landing page to ads & keywords and the reason.
  """
  prompt = build_prompt(landing_url, ads, keywords)
  result = tagging_service.describe_media(
    MediaTaggingRequest(
      tagger_type='gemini',
      media_paths=[landing_url],
      tagging_options={
        'model_name': 'gemini-3-flash-preview',
        'custom_prompt': prompt,
        'custom_schema': ScoreSchema,
      },
      media_type='WEBPAGE',
    )
  )
  try:
    score_raw = result.results[0].content.text[0].get('text').replace('\n', '')
    score = json.loads(score_raw)
  except Exception as e:
    logger.error('Failed to parse score, reason: %s', str(e))
    score = {'score': -1, 'reason': str(e)}
  return score


def build_prompt(landing_url: str, ads: list[str], keywords: list[str]) -> str:
  """Builds prompt based on landing pages, ads and keywords."""
  ads = '|'.join(list(set(ads)))
  keywords = '|'.join(list(set(keywords)))
  return PROMPT_TEMPLATE.format(
    landing_url=landing_url, ads=ads, keywords=keywords
  )


@app.command()
def main(
  dataset: Annotated[str, typer.Option(help='Dataset name')] = 'arba',
  ad_groups_to_process: Annotated[
    int, typer.Option(help='Number of top ad_groups sorted by cost')
  ] = 10,
  keywords_per_ad_group: Annotated[
    int, typer.Option(help='Number of top spending keywords per ad_group')
  ] = 10,
  log_name: Annotated[str, typer.Option(help='Name of logger')] = 'arba',
  logger_type: Annotated[str, typer.Option(help='Type of logger')] = 'local',
) -> None:
  garf_utils.init_logging(name=log_name, logger_type=logger_type)
  tagging_service = MediaTaggingService(
    repositories.SqlAlchemyTaggingResultsRepository(
      db_url=os.getenv('ARBA_DB_URI')
    )
  )

  bq_executor = BigQueryExecutor()
  query = reader.FileReader().read(query_path='./landings.sql')
  query = query.format(
    dataset=dataset,
    top_n_ad_groups=ad_groups_to_process,
    top_n_keywords=keywords_per_ad_group,
  )
  landings = bq_executor.execute(
    query=query,
    title='landings',
  )

  data = []
  bq_writer = writer.create_writer('bq', dataset=dataset)
  ad_groups_to_process = min(ad_groups_to_process, len(landings))
  report_column_names = ['ad_group_id', 'url', 'relevance_score', 'reason']
  for landing, items in landings.to_dict('url').items():
    for ad_group in items:
      if ad_groups_to_process < 0:
        report = GarfReport(
          results=data,
          column_names=report_column_names,
        )
        bq_writer.write(report, 'landing_page_relevance')
        return
      ad_group_id = ad_group.get('ad_group_id')
      logger.info('working on ad_group %s for landing %s', ad_group_id, landing)
      logger.info('%d iterations left...', ad_groups_to_process)

      score = process_landing(
        tagging_service,
        landing,
        ads=ad_group.get('ads'),
        keywords=ad_group.get('keywords'),
      )
      data.append(
        [ad_group_id, landing, score.get('score'), score.get('reason')]
      )
      ad_groups_to_process = ad_groups_to_process - 1
  report = GarfReport(
    results=data,
    column_names=report_column_names,
  )
  bq_writer.write(report, 'landing_page_relevance')
  return


if __name__ == '__main__':
  app()
