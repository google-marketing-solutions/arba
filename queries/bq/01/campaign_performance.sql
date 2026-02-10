-- Copyright 2026 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     https://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Combines Google Ads data into results of media tagging.

-- @param target_dataset BigQuery dataset to store table.
-- @param dataset BigQuery dataset where Google Ads data are stored.

CREATE OR REPLACE TABLE `{target_dataset}.campaign_performance` AS (
  SELECT
    AGM.account_id,
    AGM.account_name,
    AGM.campaign_id,
    AGM.campaign_name,
    AGM.bidding_strategy,
    AVG(CT.avg_target_cpa) AS avg_target_cpa,
    AVG(CT.avg_target_roas) AS avg_target_roas,
    ROUND(SUM(AGP.cost), 2) AS cost,
    ROUND(COALESCE(SAFE_DIVIDE(SUM(AGP.cost), SUM(AGP.conversions)), 0), 2) AS cpa,
    ROUND(COALESCE(SAFE_DIVIDE(SUM(AGP.conversions_value), SUM(AGP.cost)), 0), 2) AS roas,
    IF(
      ROUND(COALESCE(SAFE_DIVIDE(SUM(AGP.cost), SUM(AGP.conversions)), 0), 2)
      >
      ROUND(AVG(CT.avg_target_cpa), 2) ,"TRUE","FALSE"
    ) AS cpa_higher_target,
    IF(
      ROUND(COALESCE(SAFE_DIVIDE(SUM(AGP.conversions_value), SUM(AGP.cost)), 0), 2)
      <
      ROUND(AVG(CT.avg_target_roas), 2), "TRUE", "FALSE"
    ) AS roas_lower_target,
  FROM `{dataset}.ad_group_performance` AS AGP
  LEFT JOIN `{dataset}.ad_group_mapping` AS AGM
    USING(ad_group_id)
  LEFT JOIN `{dataset}.campaign_targets` AS CT
    USING(campaign_id, date)
  WHERE
    AGM.campaign_id IS NOT NULL
    AND AGP.date > CAST(CURRENT_DATE()-31 AS STRING)
  GROUP BY ALL
);
