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

-- Extracts mapping between ad_group_id and its upward hierarchy.

-- @param start_date First date of the period for ad_group performance.
-- @param end_date Last date of the period for ad_group performance.

SELECT
  customer.id AS account_id,
  customer.descriptive_name AS account_name,
  customer.currency_code AS currency_code,
  campaign.advertising_channel_type AS campaign_type,
  campaign.advertising_channel_sub_type AS campaign_subtype,
  campaign.bidding_strategy_type AS bidding_strategy,
  campaign.id AS campaign_id,
  campaign.name AS campaign_name,
  ad_group.id AS ad_group_id,
  ad_group.name AS ad_group_name
FROM  ad_group
WHERE
  AND segments.date BETWEEN '{start_date}' AND '{end_date}'
  AND metrics.cost_micros > 0
