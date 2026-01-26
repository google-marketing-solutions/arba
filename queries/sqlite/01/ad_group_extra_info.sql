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

DROP TABLE IF EXISTS ad_group_extra_info;

CREATE TABLE ad_group_extra_info AS
WITH LandingPageRelevance AS (
  SELECT
    campaign_id,
    MIN(relevance_score) AS relevance_score
  FROM landing_page_relevance
  GROUP BY 1
)
SELECT
  AGA.*,
  COALESCE(LPR.relevance_score, -1) AS relevance_score,
  U.has_usp,
  C.has_cta,
  (LOWER(AGA.headlines) || '|' || LOWER(AGA.descriptions)) REGEXP 'keyword:' AS has_dki
FROM ad_group_ad AS AGA
LEFT JOIN LandingPageRelevance AS LPR
  USING (campaign_id)
LEFT JOIN usp AS U
  ON (AGA.headlines || '|' || AGA.descriptions) = U.ad
LEFT JOIN cta AS C
  ON (AGA.headlines || '|' || AGA.descriptions) = C.ad;
