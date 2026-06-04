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

{% for i in input %}
SELECT
  {{i.ad_group_id}} AS ad_group_id,
  "{{i.url}}" AS url,
  content.text[0].relevance_score AS relevance_score,
  content.text[0].reason AS reason
FROM description
WHERE
  tagging_options.custom_prompt = "Given the following keywords and ads give me score
  of how the landing page
  is relevant to them.
  Keywords: {{i.keywords}}
  Ads: {{i.ads}}
  Landing: {{i.url}}
  "
  AND tagger_type = "gemini"
  AND media_type = "WEBPAGE"
  AND media_paths IN ([{{i.url}}])
  AND tagging_options.custom_schema = {{
    {
      "type": "object",
      "properties": {
          "relevance_score": {"type": "integer",
          "description":
            "Number from 1 to 10 where 1 means that landing page is completely irrelevant to and 10 is completely relevant"
          },
          "reason": {"type": "string", "description": "Reason for assigning a particular score."}
      }
    }
  }};
{% endfor %}
