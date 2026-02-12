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

-- Identifies whether provided ads has Call to Action in them.

-- @param ads Text ads.

SELECT
  identifier AS ad,
  content.text AS has_cta
FROM description
WHERE
  tagger.custom_prompt = "Assess the following text assets if there's any call to action in them."
  AND tagger_type = "gemini"
  AND media_type = TEXT
  AND media_paths IN ({ads})
  AND tagging_options.custom_schema = 'boolean'
