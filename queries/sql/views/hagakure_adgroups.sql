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

CREATE OR REPLACE TABLE `{target_dataset}.hagakure_adgroups` AS (
  WITH KeywordRanks AS (
    SELECT
      ad_group_id,
      keyword,
      SUM(impressions) AS impressions,
      ROW_NUMBER() OVER (PARTITION BY ad_group_id ORDER BY SUM(impressions) DESC) AS rn
    FROM
      `{target_dataset}.keyword_performance_view`
    WHERE
      date > CAST(CURRENT_DATE()-8 AS STRING)
      AND date < CAST(CURRENT_DATE() AS STRING)
    GROUP BY ALL
  ),TopKeywords AS (
    SELECT
      ad_group_id,
      STRING_AGG(keyword, ', ' ORDER BY impressions DESC) AS top_10_keywords
    FROM KeywordRanks
    WHERE
      rn <= 10
    GROUP BY 1
  )
  SELECT
    account_id,
    account_name,
    campaign_id,
    campaign_name,
    ad_group_id,
    ad_group_name,
    top_10_keywords,
    SUM(impressions) AS impressions
  FROM `{target_dataset}.keyword_performance_view`
  LEFT JOIN TopKeywords USING(ad_group_id)
  WHERE
    date > CAST(CURRENT_DATE()-8 AS STRING)
    AND date < CAST(CURRENT_DATE() AS STRING)
  GROUP BY ALL
);