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

CREATE OR REPLACE TABLE `{target_dataset}.daily_costs` AS (
  WITH KeywordPerformanceView AS (
    SELECT DISTINCT *
    FROM `{target_dataset}.keyword_performance_view`
  ),DailyCosts AS (
    SELECT
      FORMAT_DATE('%F',PARSE_DATE('%Y-%m-%d',CAST(date AS STRING))) AS date,
      ROUND(SUM(cost)) AS daily_costs
    FROM KeywordPerformanceView
    GROUP BY ALL
  )
  SELECT
    FORMAT_DATE('%F',PARSE_DATE('%Y-%m-%d',CAST(KV.date AS STRING))) AS date,
    KV.account_id,
    KV.account_name,
    KV.campaign_id,
    KV.campaign_name,
    KV.ad_group_id,
    KV.ad_group_name,
    DailyCosts.daily_costs AS daily_costs,
    ROUND(SUM(KV.cost)) AS costs
  FROM KeywordPerformanceView AS KV
  INNER JOIN DailyCosts
  ON FORMAT_DATE('%F',PARSE_DATE('%Y-%m-%d',
      CAST(KV.date AS STRING)
  )) = DailyCosts.date
  GROUP BY ALL
);