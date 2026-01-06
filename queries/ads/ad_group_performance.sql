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

-- Extracts performance metrics on ad_group_id level.

-- @param start_date First date of the period for ad_group performance.
-- @param end_date Last date of the period for ad_group performance.

SELECT
  segments.date AS date,
  campaign.advertising_channel_type AS channel_type,
  ad_group.id AS ad_group_id,
  metrics.cost_micros / 1e6 AS cost,
  metrics.conversions AS conversions,
  metrics.conversions_value AS conversions_value,
FROM ad_group
WHERE
  campaign.advertising_channel_type = SEARCH
  AND segments.date BETWEEN '{start_date}' AND '{end_date}'
  AND metrics.cost_micros > 0
