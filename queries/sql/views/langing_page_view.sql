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

CREATE OR REPLACE VIEW `{target_dataset}.landing_page_view` AS
SELECT
  campaign_id,
  REGEXP_REPLACE(SPLIT(url, '?')[0], '{.*?}', '') AS url,
  speed_score,
FROM `{dataset}.speed_score`;
