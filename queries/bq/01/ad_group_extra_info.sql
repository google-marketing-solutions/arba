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

-- @param target_dataset BigQuery dataset to store table.
-- @param dataset BigQuery dataset where Google Ads data are stored.

CREATE OR REPLACE TABLE `{target_dataset}.ad_group_extra_info` AS (
  WITH LandingPageRelevance AS (
    SELECT
      campaign_id,
      ANY_VALUE(reason) AS relevance_score_reason,
      MIN(relevance_score) AS relevance_score
    FROM `{dataset}.landing_page_relevance`
    GROUP BY 1
  ),
  DedupUsp AS (
    SELECT
      ad,
      ANY_VALUE(has_usp) AS has_usp,
      ANY_VALUE(usp_type) AS usp_type,
      ANY_VALUE(usp_strength) AS usp_strength,
      ANY_VALUE(suggestion) AS usp_suggestion
    FROM `{dataset}.usp`
    GROUP BY 1
  ),
  DedupCta AS (
    SELECT
      ad,
      ANY_VALUE(has_cta) AS has_cta,
      ANY_VALUE(cta_strength) AS cta_strength,
      ANY_VALUE(cta_type) AS cta_type
    FROM `{dataset}.cta`
    GROUP BY 1
  )
  SELECT
    AGA.*,
    IFNULL(LPR.relevance_score, -1) AS relevance_score,
    IFNULL(LPR.relevance_score_reason, 'Unknown') AS relevance_score_reason,
    U.has_usp,
    U.usp_type,
    U.usp_strength,
    U.usp_suggestion,
    C.has_cta,
    C.cta_strength,
    C.cta_type,
    REGEXP_CONTAINS(LOWER(RI.ad), 'keyword:') AS has_dki
  FROM `{dataset}.ad_group_ad` AS AGA
  LEFT JOIN LandingPageRelevance AS LPR
    USING (campaign_id)
  LEFT JOIN `{target_dataset}.rsa_input` AS RI
    USING (ad_group_ad_id)
  LEFT JOIN DedupUsp AS U
    ON U.ad = REGEXP_REPLACE(CONCAT(AGA.headlines, '|', AGA.descriptions), r'[(),]', '')
  LEFT JOIN DedupCta AS C
    ON C.ad = REGEXP_REPLACE(CONCAT(AGA.headlines, '|', AGA.descriptions), r'[(),]', '')
);
