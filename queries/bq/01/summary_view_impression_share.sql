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

-- Combines Google Ads data into a single view.

-- @param target_dataset BigQuery dataset to store view.
-- @param dataset BigQuery dataset where Google Ads data are stored.

CREATE OR REPLACE TABLE `{target_dataset}.summary_impression_grow` AS (
  WITH CampaignAggregated AS (
    SELECT
      account_id,
      account_name,
      campaign_id,
      campaign_name,
      date,
      SUM(KP.cost) AS daily_cost,
      AVG(search_impression_share) AS impression_share,
      AVG(search_top_impression_share) AS search_top_impression_share
    FROM `{dataset}.keyword_performance` AS KP
    LEFT JOIN `{dataset}.ad_group_mapping` AS AGM USING (ad_group_id)
    GROUP BY ALL
  ),
  RollingCalculation AS (
    SELECT
      account_id,
      account_name,
      campaign_id,
      campaign_name,
      SUM(daily_cost) OVER (PARTITION BY campaign_id) AS cost,
      AVG(impression_share) OVER (
        PARTITION BY campaign_id
        ORDER BY date DESC
        ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING
      ) AS impression_share_last_week,
      AVG(impression_share) OVER (
        PARTITION BY campaign_id
        ORDER BY date DESC
        ROWS BETWEEN 7 FOLLOWING AND 13 FOLLOWING
      ) AS impression_share_week_before,
      AVG(search_top_impression_share) OVER (
        PARTITION BY campaign_id
        ORDER BY date DESC
        ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING
      ) AS top_impression_share_last_week,
      AVG(search_top_impression_share) OVER (
        PARTITION BY campaign_id
        ORDER BY date DESC
        ROWS BETWEEN 7 FOLLOWING AND 13 FOLLOWING
      ) AS top_impression_share_week_before,
      ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY date DESC) AS rn
    FROM CampaignAggregated
  )
  SELECT
    account_id,
    account_name,
    campaign_id,
    campaign_name,
    cost,
    impression_share_last_week,
    impression_share_week_before,
    top_impression_share_last_week,
    top_impression_share_week_before
  FROM RollingCalculation
  WHERE rn = 1
);
