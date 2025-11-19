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
  campaign.maximize_conversions.target_cpa_micros AS maximize_conversions_target_cpa,
  campaign.target_cpa.target_cpa_micros / 1e6 AS target_cpa,
  campaign.target_roas.target_roas AS target_roas,
  campaign.maximize_conversion_value.target_roas AS maximize_conversions_target_roas,
  campaign.id AS campaign_id,
  campaign.name AS campaign_name,
  ad_group.id AS ad_group_id,
  ad_group.name AS ad_group_name,
  metrics.cost_micros / 1e6 AS cost,
  metrics.conversions AS conversions,
  metrics.conversions_value AS conversions_value,
  metrics.bounce_rate AS bounce_rate
FROM ad_group
WHERE
  campaign.advertising_channel_type = SEARCH
  AND segments.date BETWEEN '{start_date}' AND '{end_date}'
  AND metrics.cost_micros > 0
