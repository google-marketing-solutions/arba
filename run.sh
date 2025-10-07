# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

fetch_ads_data() {
  gaarf queries/ads/landing_pages.sql \
    --account $GOOGLE_ADS_ACCOUNT \
    --ads-config $GOOGLE_ADS_CONFIGURATION_FILE_PATH \
    --customer-id-query 'SELECT customer.id FROM campaign WHERE campaign.advertising_channel_type = SEARCH' \
    --macro.start-date=:YYYYMMDD-30 \
    --macro.end-date=:YYYYMMDD-1 \
    --output bq \
    --bq.project=$GOOGLE_CLOUD_PROJECT \
    --bq.dataset=arba
}

get_landings() {
  garf queries/sql/inputs/landings.sql \
    --source bq \
    --source.project-id=$GOOGLE_CLOUD_PROJECT \
    --macro.dataset=arba \
    --output csv \
    --csv.destination-folder=/tmp

}
tag_landing_pages() {
  get_landings
  local prompt="Summarize the key information from the provided URL. Focus on the main purpose and key takeaways, plus as well as focusing on meta tags content, especially meta tag 'description' "
  media-tagger describe --input /tmp/landings.csv \
    --input.column_name=final_urls --input.skip-row=1 \
    --media-type WEBPAGE \
    --tagger gemini \
    --tagger.model-name=gemini-2.5-flash \
    --tagger.custom-prompt="$prompt" \
    --tagger.custom-schema=./schema.json \
    --writer bq \
    --output landing_info \
    --bq.project=$GOOGLE_CLOUD_PROJECT \
    --bq.array-handling=strings \
    --bq.dataset=arba
}


generate_bq_views() {
  garf queries/sql/views/*.sql \
    --source bq \
    --source.project-id=$GOOGLE_CLOUD_PROJECT \
    --macro.target_dataset=arba_output \
    --macro.dataset=arba
}

fetch_ads_data
tag_landing_pages
generate_bq_views
