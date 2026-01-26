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

DROP TABLE IF EXISTS keyword_performance_view;

CREATE TABLE keyword_performance_view AS
SELECT DISTINCT
  AGM.account_id,
  AGM.account_name,
  AGM.currency_code,
  AGM.campaign_type,
  AGM.campaign_subtype,
  AGM.bidding_strategy,
  AGM.campaign_id,
  AGM.campaign_name,
  AGM.ad_group_name,
  KM.keyword,
  KM.match_type,
  KP.*
FROM keyword_performance AS KP
INNER JOIN ad_group_mapping AS AGM
  ON KP.ad_group_id = AGM.ad_group_id
INNER JOIN keyword_mapping AS KM
  ON KP.keyword_id = KM.keyword_id
    AND AGM.account_id = KM.account_id;

-- Combines Google Ads data into a single table.

DROP TABLE IF EXISTS daily_costs;

CREATE TABLE daily_costs AS
WITH DailyCosts AS (
  SELECT
    date,
    ROUND(SUM(cost)) AS daily_costs
  FROM keyword_performance_view
  GROUP BY
    date
)
SELECT
  KPV.date,
  KPV.account_id,
  KPV.account_name,
  KPV.campaign_id,
  KPV.campaign_name,
  KPV.ad_group_id,
  KPV.ad_group_name,
  DailyCosts.daily_costs AS daily_costs,
  ROUND(SUM(KPV.cost)) AS costs
FROM keyword_performance_view AS KPV
INNER JOIN DailyCosts USING (date)
GROUP BY
  KPV.date,
  KPV.account_id,
  KPV.account_name,
  KPV.campaign_id,
  KPV.campaign_name,
  KPV.ad_group_id,
  KPV.ad_group_name,
  DailyCosts.daily_costs;
