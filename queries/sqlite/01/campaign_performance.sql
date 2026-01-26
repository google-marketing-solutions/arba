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

-- Combines Google Ads data into results of media tagging.

DROP TABLE IF EXISTS campaign_performance;

CREATE TABLE campaign_performance AS
SELECT
  AGM.account_id,
  AGM.account_name,
  AGM.campaign_id,
  AGM.campaign_name,
  AGM.bidding_strategy,
  AVG(CT.avg_target_cpa) AS avg_target_cpa,
  AVG(CT.avg_target_roas) AS avg_target_roas,
  ROUND(SUM(AGP.cost), 2) AS cost,
  ROUND(IIF(SUM(AGP.conversions) = 0, 0, SUM(AGP.cost) * 1.0 / SUM(AGP.conversions)), 2) AS cpa,
  ROUND(IIF(SUM(AGP.cost) = 0, 0, SUM(AGP.conversions_value) * 1.0 / SUM(AGP.cost)), 2) AS roas,
  IIF(SUM(AGP.conversions) = 0, 0, SUM(AGP.cost) * 1.0 / SUM(AGP.conversions))
    > AVG(CT.avg_target_cpa) AS cpa_higher_target,
  IIF(SUM(AGP.cost) = 0, 0, SUM(AGP.conversions_value) * 1.0 / SUM(AGP.cost))
    < AVG(CT.avg_target_roas) AS roas_lower_target
FROM ad_group_performance AS AGP
LEFT JOIN ad_group_mapping AS AGM
  ON AGP.ad_group_id = AGM.ad_group_id
LEFT JOIN campaign_targets AS CT
  ON CT.campaign_id = AGM.campaign_id AND CT.date = AGP.date
WHERE
  AGM.campaign_id IS NOT NULL
  AND AGP.date > DATE('now', '-30 days')
GROUP BY 1, 2, 3, 4, 5;
