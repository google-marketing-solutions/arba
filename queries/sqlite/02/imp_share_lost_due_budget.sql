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

DROP TABLE IF EXISTS imp_share_lost_due_budget;

CREATE TABLE imp_share_lost_due_budget AS
SELECT
  account_id,
  account_name,
  campaign_id,
  campaign_name,
  ad_group_id,
  ad_group_name,
  keyword,
  SUM(cost) AS costs,
  MAX(search_budget_lost_absolute_top_impression_share) AS lost_due_budget,
  "Increase the budget" AS recommended_action
FROM
  keyword_performance_view
WHERE
  date > DATE('now', '-8 days')
  AND date < DATE('now')
GROUP BY
  account_id,
  account_name,
  campaign_id,
  campaign_name,
  ad_group_id,
  ad_group_name,
  keyword
HAVING lost_due_budget > 0.1;
