-- Copyright 2026 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Combines Google Ads data into a single table.

DROP TABLE IF EXISTS quality_score_recommendations;

CREATE TABLE quality_score_recommendations AS
WITH AverageCtr AS (
  SELECT
    account_id,
    campaign_id,
    ad_group_id,
    IIF(
      SUM(impressions) = 0,
      0.0,
      SUM(clicks) / SUM(impressions)
      ) AS average_ctr
  FROM keyword_performance_view
  GROUP BY
    account_id,
    campaign_id,
    ad_group_id
)
SELECT
  KPV.account_id,
  KPV.account_name,
  KPV.campaign_id,
  KPV.campaign_name,
  KPV.ad_group_id,
  KPV.ad_group_name,
  KPV.keyword_id,
  KPV.keyword,
  AC.average_ctr,
  ROUND(SUM(KPV.cost), 0) AS costs,
  IIF(
    SUM(KPV.impressions) = 0,
    0.0,
    SUM(KPV.clicks) / SUM(KPV.impressions)
    ) AS keyword_ctr,
  CASE
    WHEN
      2 * IIF(
        SUM(KPV.impressions) = 0,
        0.0,
        SUM(KPV.clicks) / SUM(KPV.impressions)
        ) < AC.average_ctr
      AND SUM(KPV.clicks) > 10 AND SUM(KPV.conversions) = 0
    THEN "Pause Keyword"
    ELSE "Add keyword to your Landing Page AND/OR Ad Copy"
  END AS keyword_recommendation
FROM keyword_performance_view AS KPV
LEFT JOIN AverageCtr AS AC USING (account_id, campaign_id, ad_group_id)
WHERE KPV.date > DATE('now', '-90 days')
GROUP BY
  KPV.account_id,
  KPV.account_name,
  KPV.campaign_id,
  KPV.campaign_name,
  KPV.ad_group_id,
  KPV.ad_group_name,
  KPV.keyword_id,
  KPV.keyword,
  AC.average_ctr
HAVING MAX(KPV.quality_score) < 7 AND MIN(KPV.quality_score) != 0
ORDER BY costs DESC;
