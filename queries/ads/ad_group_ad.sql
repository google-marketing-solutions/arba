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

-- Extracts mapping between ad_group_id and responsive search ads.

-- @param start_date First date of the period for ad group ad performance.
-- @param end_date Last date of the period for ad group ad performance.

SELECT
  customer.id AS account_id,
  customer.descriptive_name AS account_name,
  campaign.id AS campaign_id,
  campaign.name AS campaign_name,
  ad_group.id AS ad_group_id,
  ad_group.name AS ad_group_name,
  ad_group_ad.ad.id AS ad_group_ad_id,
  ad_group_ad.ad_strength AS ad_group_ad_strength,
  metrics.cost_micros / 1e6 AS cost
FROM ad_group_ad
WHERE
  ad_group_ad.ad.type = 'RESPONSIVE_SEARCH_AD'
  AND metrics.cost_micros > 0
  AND segments.date BETWEEN '{start_date}' AND '{end_date}'