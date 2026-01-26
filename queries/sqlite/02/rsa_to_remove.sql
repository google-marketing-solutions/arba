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

-- Combines Google Ads data into a single view.

DROP TABLE IF EXISTS rsa_to_remove;

CREATE TABLE rsa_to_remove AS
WITH AdGroupAdStrength AS (
  SELECT
    AGA.account_id,
    AGA.account_name,
    AGA.campaign_id,
    AGA.campaign_name,
    AGA.ad_group_id,
    AGA.ad_group_name,
    AGA.ad_group_ad_id,
    AGA.ad_group_ad_strength,
    CASE
      WHEN AGA.ad_group_ad_strength = "EXCELLENT" THEN 4
      WHEN AGA.ad_group_ad_strength = "GOOD" THEN 3
      WHEN AGA.ad_group_ad_strength = "AVERAGE" THEN 2
      WHEN AGA.ad_group_ad_strength = "POOR" THEN 1
      ELSE 0
    END AS ad_strength_mapped,
    AGA.cost
  FROM ad_group_ad AS AGA
  INNER JOIN rsa_count AS RC
    ON AGA.ad_group_id = RC.ad_group_id
  WHERE RC.has_more_than_one_rsa = 1
),
AdGroupAdStrengthRanked AS (
  SELECT
    *,
    DENSE_RANK() OVER (
      PARTITION BY ad_group_id
      ORDER BY ad_strength_mapped DESC,
      cost DESC
    ) AS ad_strength_rank
  FROM AdGroupAdStrength
)
SELECT
  *
FROM AdGroupAdStrengthRanked
WHERE ad_strength_rank > 1;
