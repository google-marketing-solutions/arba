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

-- Extracts campaign-level ai max feature adoption

-- @param start_date First date of the period for campaign performance.
-- @param end_date Last date of the period for campaign performance.

SELECT
  customer.id AS account_id,
  customer.descriptive_name AS account_name,
  campaign.id AS campaign_id,
  campaign.name AS campaign_name,
  campaign.ai_max_setting.enable_ai_max AS ai_max_status,
  campaign.asset_automation_settings:asset_automation_type
    AS asset_automation_types,
  campaign.asset_automation_settings:asset_automation_status
    AS asset_automation_statuses,
  metrics.cost_micros / 1e6 AS cost
FROM campaign
WHERE
  campaign.advertising_channel_type = SEARCH
  AND segments.date BETWEEN '{start_date}' AND '{end_date}'
  AND metrics.cost_micros > 0