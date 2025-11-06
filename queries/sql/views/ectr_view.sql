-- Copyright 2025 Google LLC
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

-- Combines Google Ads data into a single table.

-- @param target_dataset BigQuery dataset to store table.
-- @param dataset BigQuery dataset where Google Ads data are stored.

CREATE OR REPLACE TABLE `{target_dataset}.ectr_view` AS (
  WITH KeywordPerformanceView AS (
    SELECT DISTINCT *
    FROM `{target_dataset}.keyword_performance_view`
  )
  SELECT
    FORMAT_DATE('%F',PARSE_DATE('%Y-%m-%d',CAST(KV.date AS STRING))) AS date,
    KV.account_id,
    KV.account_name,
    KV.campaign_id,
    KV.campaign_name,
    KV.ad_group_id,
    KV.ad_group_name,
    CASE
      WHEN KV.historical_search_predicted_ctr = "UNSPECIFIED" THEN 0
      WHEN KV.historical_search_predicted_ctr = "BELOW_AVERAGE" THEN 1
      WHEN KV.historical_search_predicted_ctr = "AVERAGE" THEN 2
      WHEN KV.historical_search_predicted_ctr = "ABOVE_AVERAGE" THEN 3
    END AS ectr,
    ROUND(SUM(KV.cost)) AS costs,
    DailyCosts.daily_costs AS daily_costs
  FROM KeywordPerformanceView AS KV
  INNER JOIN `{target_dataset}.daily_costs` AS DailyCosts
    ON FORMAT_DATE('%F',PARSE_DATE('%Y-%m-%d',
        CAST(KV.date AS STRING)
    )) = DailyCosts.date
    AND KV.account_id = DailyCosts.account_id
    AND KV.campaign_id = DailyCosts.campaign_id
    AND KV.ad_group_id = DailyCosts.ad_group_id
  GROUP BY ALL
);