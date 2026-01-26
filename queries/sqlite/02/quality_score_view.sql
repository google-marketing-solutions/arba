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

-- Combines Google Ads data into a single table.

DROP TABLE IF EXISTS quality_score_view;

CREATE TABLE quality_score_view AS
SELECT
  KPV.date,
  KPV.account_id,
  KPV.account_name,
  KPV.campaign_id,
  KPV.campaign_name,
  KPV.ad_group_id,
  KPV.ad_group_name,
  CAST(COALESCE(KPV.quality_score,0) AS INTEGER) AS qs,
  ROUND(SUM(KPV.cost)) AS costs,
  DailyCosts.daily_costs AS daily_costs
FROM keyword_performance_view AS KPV
INNER JOIN daily_costs AS DailyCosts
  USING (date, account_id, campaign_id, ad_group_id)
GROUP BY
  KPV.date,
  KPV.account_id,
  KPV.account_name,
  KPV.campaign_id,
  KPV.campaign_name,
  KPV.ad_group_id,
  KPV.ad_group_name,
  qs;
