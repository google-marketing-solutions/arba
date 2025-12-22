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

CREATE OR REPLACE TABLE `{target_dataset}.hagakure_landing_pages` AS (
  WITH AdGroupData AS (
    SELECT
      AGM.account_id,
      AGM.account_name,
      LP.campaign_id,
      AGM.campaign_name,
      LP.ad_group_id,
      AGM.ad_group_name,
      LP.final_urls
    FROM `{target_dataset}.landing_pages` LP
    INNER JOIN `{target_dataset}.ad_group_mapping` AGM
      ON LP.ad_group_id = AGM.ad_group_id
  )
  SELECT
    account_id,
    account_name,
    final_urls AS landing_page,
    ARRAY_TO_STRING(
      ARRAY_AGG(
        DISTINCT CAST(ad_group_id AS STRING)
      ),"\n") AS ad_groups,
    ARRAY_TO_STRING(
      ARRAY_AGG(
        DISTINCT CAST(ad_group_name AS STRING)
      ),"\n") AS ad_groups_names,
    IF(
      ARRAY_LENGTH(ARRAY_AGG(DISTINCT ad_group_id)) > 1,
      TRUE,
      FALSE
    ) AS requiring_attention
  FROM AdGroupData
  GROUP BY ALL
);