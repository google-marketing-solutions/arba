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
WITH
  Keywords AS (
    SELECT
      campaign_id,
      ARRAY_AGG(keyword) AS keywords
    FROM `{dataset}.keyword_mapping`
    GROUP BY 1
  ),
  Ads AS (
    SELECT
      campaign_id,
      ARRAY_AGG(headlines) AS headlines,
      ARRAY_AGG(descriptions) AS descriptions
    FROM `{dataset}.ad_group_ad`
    GROUP BY 1
  ),
  Landings AS (
    SELECT DISTINCT
      campaign_id,
      final_urls AS url
    FROM `{dataset}.landing_pages`
  )
SELECT
  L.campaign_id,
  L.url,
  ARRAY_SLICE(K.keywords, 0, 10) AS keywords,
  ARRAY_CONCAT(A.headlines, A.descriptions) AS ads
FROM Landings AS L
LEFT JOIN Keywords AS K USING(campaign_id)
LEFT JOIN Ads AS A USING(campaign_id);
