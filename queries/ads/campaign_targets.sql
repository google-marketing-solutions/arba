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

-- Extracts average bidding targets for each day of a period.

-- @param start_date First date of the period for ad_group performance.
-- @param end_date Last date of the period for ad_group performance.

SELECT
  segments.date AS date,
  campaign.advertising_channel_type AS channel_type,
  campaign.id AS campaign_id,
  metrics.average_target_cpa_micros / 1e6 AS avg_target_cpa,
  metrics.average_target_roas AS avg_target_roas
FROM campaign
WHERE
  campaign.advertising_channel_type = SEARCH
  AND segments.date BETWEEN '{start_date}' AND '{end_date}'
  AND metrics.cost_micros > 0
