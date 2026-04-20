# Copyright 2026 Google LLC
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

"""Scores CTA and USP quality for RSA text ads."""

import json
import logging
import os
from typing import Literal

import pydantic
import typer
from garf.core.report import GarfReport
from garf.executors.bq_executor import BigQueryExecutor
from garf.executors.entrypoints import utils as garf_utils
from garf.io import writer
from media_tagging import MediaTaggingRequest, MediaTaggingService, repositories
from typing_extensions import Annotated

logger = logging.getLogger('arba.scripts.ad_copy_score')

app = typer.Typer()

MODEL_NAME = 'gemini-3-flash-preview'

CTA_PROMPT = """
Analyze the ad copy for Call-to-Action quality.
Return only a JSON object with the following schema:
{{
  "has_cta": "<boolean>",
  "cta_strength": "<integer from 1 to 5 where 1 means no CTA or weak/vague CTA, 3 means a basic CTA is present, and 5 means a strong action-oriented CTA with urgency or value proposition>",
  "cta_type": "<one of: direct_action, curiosity, urgency, social_proof, none>"
}}
Use cta_type="none" when has_cta is false.
Ad copy: {ad}
"""

USP_PROMPT = """
Analyze the ad copy for Unique Selling Proposition.
Return only a JSON object with the following schema:
{{
  "has_usp": "<boolean>",
  "usp_type": "<one of: price_advantage, speed, exclusivity, guarantee, authority, innovation, convenience, none>",
  "usp_strength": "<integer from 1 to 5 where 1 means no clear USP and 5 means compelling differentiated value>",
  "suggestion": "<specific recommendation to strengthen the USP>"
}}
Use usp_type="none" when has_usp is false.
Evaluate against competitors in the same niche if possible.
Ad copy: {ad}
"""

ADS_QUERY = """
SELECT DISTINCT ad
FROM `{dataset}.rsa_input`
WHERE
  cost_share < {cost_share}
  OR ad_position <= {max_results}
ORDER BY ad
"""


class CtaSchema(pydantic.BaseModel):
  has_cta: bool = pydantic.Field(description='whether the ad copy includes CTA')
  cta_strength: int = pydantic.Field(ge=1, le=5)
  cta_type: Literal[
    'direct_action', 'curiosity', 'urgency', 'social_proof', 'none'
  ]


class UspSchema(pydantic.BaseModel):
  has_usp: bool = pydantic.Field(description='whether the ad copy includes USP')
  usp_type: Literal[
    'price_advantage',
    'speed',
    'exclusivity',
    'guarantee',
    'authority',
    'innovation',
    'convenience',
    'none',
  ]
  usp_strength: int = pydantic.Field(ge=1, le=5)
  suggestion: str


def build_request(
  ad: str, prompt: str, schema: type[pydantic.BaseModel]
) -> MediaTaggingRequest:
  return MediaTaggingRequest(
    tagger_type='gemini',
    media_paths=[ad],
    tagging_options={
      'model_name': MODEL_NAME,
      'custom_prompt': prompt,
      'custom_schema': schema,
    },
    media_type='TEXT',
  )


def parse_response(
  result,
  schema: type[pydantic.BaseModel],
  fallback: dict[str, str | int | bool],
) -> dict[str, str | int | bool]:
  try:
    raw = result.results[0].content.text[0]
    if isinstance(raw, dict):
      parsed = schema.model_validate(raw)
    else:
      parsed = schema.model_validate(json.loads(str(raw).replace('\n', '')))
    return parsed.model_dump()
  except Exception as e:
    logger.error('Failed to parse %s response: %s', schema.__name__, str(e))
    return fallback


def process_ad(
  tagging_service: MediaTaggingService, ad: str
) -> tuple[dict[str, str | int | bool], dict[str, str | int | bool]]:
  cta_result = tagging_service.describe_media(
    build_request(ad, CTA_PROMPT.format(ad=ad), CtaSchema)
  )
  usp_result = tagging_service.describe_media(
    build_request(ad, USP_PROMPT.format(ad=ad), UspSchema)
  )

  cta = parse_response(
    cta_result,
    CtaSchema,
    {'has_cta': False, 'cta_strength': 1, 'cta_type': 'none'},
  )
  usp = parse_response(
    usp_result,
    UspSchema,
    {
      'has_usp': False,
      'usp_type': 'none',
      'usp_strength': 1,
      'suggestion': 'Failed to parse Gemini response',
    },
  )
  return cta, usp


@app.command()
def main(
  dataset: Annotated[str, typer.Option(help='Dataset name')] = 'arba',
  cost_share: Annotated[
    int, typer.Option(help='Cost share threshold for CTA/USP processing')
  ] = 80,
  max_results: Annotated[
    int, typer.Option(help='Number of top ads to process regardless of cost share')
  ] = 100,
  log_name: Annotated[str, typer.Option(help='Name of logger')] = 'arba',
  logger_type: Annotated[str, typer.Option(help='Type of logger')] = 'local',
) -> None:
  garf_utils.init_logging(name=log_name, logger_type=logger_type)

  bq_executor = BigQueryExecutor()
  query = ADS_QUERY.format(
    dataset=dataset, cost_share=cost_share, max_results=max_results
  )
  ads = bq_executor.execute(query=query, title='rsa_input_ads')
  if len(ads) == 0:
    logger.info('No RSA ads to process for CTA/USP scoring')
    return

  tagging_service = MediaTaggingService(
    repositories.SqlAlchemyTaggingResultsRepository(
      db_url=os.getenv('ARBA_DB_URI')
    )
  )

  cta_rows = []
  usp_rows = []
  for ad in ads.to_dict('ad').keys():
    logger.info('Processing CTA/USP for ad: %s', ad)
    cta, usp = process_ad(tagging_service, ad)
    cta_rows.append(
      [ad, cta.get('has_cta'), cta.get('cta_strength'), cta.get('cta_type')]
    )
    usp_rows.append(
      [
        ad,
        usp.get('has_usp'),
        usp.get('usp_type'),
        usp.get('usp_strength'),
        usp.get('suggestion'),
      ]
    )

  bq_writer = writer.create_writer('bq', dataset=dataset)
  cta_report = GarfReport(
    results=cta_rows,
    column_names=['ad', 'has_cta', 'cta_strength', 'cta_type'],
  )
  usp_report = GarfReport(
    results=usp_rows,
    column_names=['ad', 'has_usp', 'usp_type', 'usp_strength', 'suggestion'],
  )
  bq_writer.write(cta_report, 'cta')
  bq_writer.write(usp_report, 'usp')


if __name__ == '__main__':
  app()
