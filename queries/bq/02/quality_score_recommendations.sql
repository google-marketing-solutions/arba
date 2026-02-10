-- Copyright 2025 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Combines Google Ads data into a single table.

-- @param target_dataset BigQuery dataset to store table.
-- @param dataset BigQuery dataset where Google Ads data are stored.

CREATE OR REPLACE TABLE `{target_dataset}.quality_score_recommendations` AS (
  WITH AverageCtr AS (
    SELECT
      account_id,
      campaign_id,
      ad_group_id,
      SAFE_DIVIDE(SUM(clicks), SUM(impressions)) AS average_ctr
    FROM `{target_dataset}.keyword_performance_view`
    GROUP BY ALL
  )
  SELECT
    KPV.account_id,
    KPV.account_name,
    KPV.campaign_id,
    KPV.campaign_name,
    KPV.ad_group_id,
    KPV.ad_group_name,
    KPV.keyword_id,
    KPV.keyword,
    AC.average_ctr,
    ROUND(SUM(KPV.cost), 0) AS costs,
    SAFE_DIVIDE(SUM(KPV.clicks), SUM(KPV.impressions)) AS keyword_ctr,
    IF(
      2 * SAFE_DIVIDE(SUM(KPV.clicks), SUM(KPV.impressions)) < AC.average_ctr
      AND SUM(KPV.clicks) > 10 AND SUM(KPV.conversions) = 0,
      "Pause Keyword",
      "Add keyword to your Landing Page AND/OR Ad Copy"
    ) AS keyword_recommendation
  FROM `{target_dataset}.keyword_performance_view` AS KPV
  LEFT JOIN AverageCtr AS AC USING (account_id, campaign_id, ad_group_id)
  WHERE CAST(KPV.date AS DATE) > CURRENT_DATE() - 90
  GROUP BY ALL
  HAVING (MAX(KPV.quality_score) < 7 AND NOT MIN(KPV.quality_score) = 0)
  ORDER BY costs DESC
);
