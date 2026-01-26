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

DROP TABLE IF EXISTS ai_max_summary;

CREATE TABLE ai_max_summary AS
SELECT
  account_id,
  account_name,
  campaign_id,
  campaign_name,
  ai_max_status,
  asset_automation_statuses,
  asset_automation_types,
  IIF(INSTR(asset_automation_statuses, '|') > 0, SUBSTR(asset_automation_statuses, 1, INSTR(asset_automation_statuses, '|') - 1), asset_automation_statuses)
    AS text_asset_automation_status,
  COALESCE(IIF(INSTR(asset_automation_statuses, '|') > 0, SUBSTR(asset_automation_statuses, INSTR(asset_automation_statuses, '|') + 1), NULL), 'OPTED_OUT')
    AS final_url_expansion,
  cost
FROM campaign_ai_max;
