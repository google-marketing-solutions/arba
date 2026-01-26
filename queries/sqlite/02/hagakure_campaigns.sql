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

DROP TABLE IF EXISTS hagakure_campaigns;

CREATE TABLE hagakure_campaigns AS
SELECT
  account_id,
  account_name,
  campaign_id,
  campaign_name,
  ROUND(SUM(conversions), 0) AS conversions
FROM keyword_performance_view
WHERE
  date > DATE('now', '-31 days')
  AND date < DATE('now')
GROUP BY
  account_id,
  account_name,
  campaign_id,
  campaign_name;
