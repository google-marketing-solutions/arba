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

CREATE OR REPLACE TABLE `{target_dataset}.rsa_count` AS (
  WITH AdGroupAd AS (
    SELECT
      account_id,
      account_name,
      campaign_id,
      campaign_name,
      ad_group_id,
      ad_group_name,
      COUNT(DISTINCT ad_group_ad_id) AS rsa_count,
      ROUND(SUM(cost), 0) AS cost
    FROM `{dataset}.ad_group_ad`
    GROUP BY ALL
  )
  SELECT
    account_id,
    account_name,
    campaign_id,
    campaign_name,
    ad_group_id,
    ad_group_name,
    cost,
    rsa_count = 1 AS has_more_than_one_rsa,
  FROM AdGroupAd
);
