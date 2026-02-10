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

-- Extracts responsive search ads texts.

-- @param dataset Name of BigQuery dataset.

CREATE OR REPLACE TABLE `{target_dataset}.rsa_input` AS (
  WITH AdGroupAds AS (
    SELECT
      ad_group_ad_id,
      REGEXP_REPLACE(CONCAT(headlines, '|', descriptions), r'[(),]', '') AS ad,
      SUM(cost) AS cost,
    FROM `{dataset}.ad_group_ad`
    GROUP BY ALL
    HAVING cost > 0
    ORDER BY cost DESC
  ),
  Positions AS (
    SELECT
      ad_group_ad_id,
      ad,
      ROW_NUMBER() OVER() AS  position,
      cost
    FROM AdGroupAds
  )
  SELECT
    ad_group_ad_id,
    ad,
    cost,
    SUM(cost) OVER (ORDER BY position) / SUM(cost) OVER() * 100 AS cost_share
  FROM Positions
);
