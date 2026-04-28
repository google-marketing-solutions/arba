/*Copyright 2025 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

-- Fetches unique final_urls.

-- @param dataset BigQuery dataset where Google Ads data are stored.
-- @param top_ad_groups Number of top campaigns to process.
-- @param top_n_keywords Number of top keywords to get from each campaign.

WITH
  TopAdGroups AS (
    SELECT
      ad_group_id,
      SUM(cost) AS cost
    FROM `{dataset}.landing_pages`
    GROUP BY 1
    ORDER BY cost DESC
    LIMIT {top_n_ad_groups}
  ),
  KeywordCost AS (
    SELECT
      KP.ad_group_id,
      KM.keyword,
      SUM(KP.cost) AS cost
    FROM `{dataset}.keyword_performance` AS KP
    INNER JOIN `{dataset}.ad_group_mapping` AS AGM
      ON KP.ad_group_id = AGM.ad_group_id
    INNER JOIN `{dataset}.keyword_mapping` AS KM
      ON KP.keyword_id = KM.keyword_id
        AND AGM.account_id = KM.account_id
    GROUP BY 1, 2
  ),
  TopAdGroupKeywords AS (
    SELECT
      ad_group_id,
      keyword,
      ROW_NUMBER() OVER(
        PARTITION BY ad_group_id
        ORDER BY cost
      ) AS keyword_rank
    FROM KeywordCost
  ),
  Keywords AS (
    SELECT
      TAGK.ad_group_id,
      ARRAY_AGG(TAGK.keyword) AS keywords
    FROM TopAdGroupKeywords AS TAGK
    INNER JOIN TopAdGroups USING (ad_group_id)
    WHERE TAGK.keyword_rank <= {top_n_keywords}
    GROUP BY 1
  ),
  Ads AS (
    SELECT
      AGA.ad_group_id,
      ARRAY_AGG(AGA.headlines) AS headlines,
      ARRAY_AGG(AGA.descriptions) AS descriptions
    FROM `{dataset}.ad_group_ad` AS AGA
    INNER JOIN TopAdGroups USING (ad_group_id)
    GROUP BY 1
  ),
  Landings AS (
    SELECT DISTINCT
      LP.ad_group_id,
      LP.final_urls AS url
    FROM `{dataset}.landing_pages` AS LP
    INNER JOIN TopAdGroups USING (ad_group_id)
  )
SELECT
  L.ad_group_id,
  L.url,
  K.keywords,
  ARRAY_CONCAT(A.headlines, A.descriptions) AS ads
FROM Landings AS L
LEFT JOIN Keywords AS K USING (ad_group_id)
LEFT JOIN Ads AS A USING (ad_group_id);
