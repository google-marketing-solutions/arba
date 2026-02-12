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
  ProcessedCta AS (
    SELECT DISTINCT
      ad,
      ANY_VALUE(has_cta) AS has_cta
    FROM `{dataset}.cta`
    GROUP BY 1
  ),
  ProcessedUsp AS (
    SELECT DISTINCT
      ad,
      ANY_VALUE(has_usp) AS has_usp
    FROM `{dataset}.usp`
    GROUP BY 1
  ),
  Positions AS (
    SELECT
      AGA.ad_group_ad_id,
      AGA.ad,
      ROW_NUMBER() OVER() AS position,
      AGA.cost,
      PC.has_cta IS NULL AS unprocessed_cta,
      PU.has_usp IS NULL AS unprocessed_usp
    FROM AdGroupAds AS AGA
    LEFT JOIN ProcessedCta AS PC
      USING (ad)
    LEFT JOIN ProcessedUSP AS PU
      USING (ad)
  )
  SELECT
    ad_group_ad_id,
    ad,
    cost,
    position AS ad_position,
    SUM(cost) OVER (ORDER BY position) / SUM(cost) OVER() * 100 AS cost_share
  FROM Positions
  WHERE unprocessed_cta OR unprocessed_usp
);
