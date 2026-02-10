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

-- Extracts keyword specific metrics by day.

-- @param start_date First date of the period for keyword performance.
-- @param end_date Last date of the period for keyword performance.

SELECT
  segments.date AS date,
  ad_group.id AS ad_group_id,
  ad_group_criterion.criterion_id AS keyword_id,
  metrics.cost_micros / 1e6 AS cost,
  metrics.impressions AS impressions,
  metrics.clicks AS clicks,
  metrics.conversions AS conversions,
  metrics.conversions_value AS conversions_values,
  metrics.historical_quality_score AS quality_score,
  metrics.historical_landing_page_quality_score AS landing_page_experience,
  metrics.historical_creative_quality_score AS ad_relevance,
  metrics.historical_search_predicted_ctr AS expected_ctr,
  metrics.search_budget_lost_absolute_top_impression_share
    AS search_budget_lost_absolute_top_impression_share,
  metrics.search_rank_lost_impression_share AS search_rank_lost_impression_share,
  metrics.search_impression_share AS search_impression_share,
  metrics.search_absolute_top_impression_share AS search_absolute_top_impression_share,
  metrics.search_top_impression_share AS search_top_impression_share
FROM  keyword_view
WHERE
  ad_group_criterion.negative = FALSE
  AND segments.date BETWEEN '{start_date}' AND '{end_date}'
  AND metrics.cost_micros > 0
