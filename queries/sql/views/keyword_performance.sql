-- Copyright 2025 Google LLC
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

-- @param target_dataset BigQuery dataset to store view.
-- @param dataset BigQuery dataset where Google Ads data are stored.

CREATE OR REPLACE VIEW `{target_dataset}.keyword_performance_view` AS
SELECT
  A.account_id,
  A.account_name,
  A.currency_code,
  A.campaign_type,
  A.campaign_subtype,
  A.bidding_strategy,
  A.campaign_id,
  A.campaign_name,
  A.ad_group_name,
  K.keyword,
  K.match_type,
  P.*
FROM `{dataset}.keyword_performance` AS P
INNER JOIN `{dataset}.ad_group_mapping` AS A
  ON P.ad_group_id= A.ad_group_id
INNER JOIN `{dataset}.keyword_mapping` AS K
  ON P.keyword_id = K.keyword_id
    AND A.account_id= K.account_id;
