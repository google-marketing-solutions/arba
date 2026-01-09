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

usage() {
    echo "Usage: $0 -d <dataset> -p <project> -a <ads-config> -s <start_date> -e <end_date> -c <account> -l <logger_type>"
    exit 1
}

while getopts "d:p:a:s:e:m:c:t:" opt; do
    case $opt in
        d) BQ_DATASET="$OPTARG" ;;
        p) GOOGLE_CLOUD_PROJECT="$OPTARG" ;;
        a) ADS_CONFIG="$OPTARG" ;;
        s) START_DATE="$OPTARG" ;;
        e) END_DATE="$OPTARG" ;;
        c) GOOGLE_ADS_ACCOUNT="$OPTARG" ;;
        t) TAGGING_ENABLED="$OPTARG" ;;
        l) LOGGER="$OPTARG" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

if [ -z "$GOOGLE_ADS_ACCOUNT" ]; then
    echo "Provide Google Ads account."
    exit 1
fi

if [ -z "$ADS_CONFIG" ]; then
  echo "google-ads.yaml not provided. Using default ~/google-ads.yaml"
  GOOGLE_ADS_CONFIG=$HOME/google-ads.yaml
fi

if [ -z "$BQ_DATASET" ]; then
  BQ_DATASET='arba'
fi

if [ -z "$START_DATE" ]; then
  START_DATE=:YYYYMMDD-30
fi

if [ -z "$END_DATE" ]; then
  END_DATE=:YYYYMMDD-1
fi

if [ -z "$TAGGING_ENABLED" ]; then
  TAGGING_ENABLED=0
else
  TAGGING_ENABLED=1
fi
if [ -z "$LOGGER" ]; then
  LOGGER='rich'
fi

fetch_ads_data() {
  garf queries/ads/*.sql --source google-ads \
    --source.account=$GOOGLE_ADS_ACCOUNT \
    --source.path-to-config=$ADS_CONFIG \
    --source.customer-id-query='SELECT customer.id FROM campaign WHERE campaign.advertising_channel_type = SEARCH' \
    --macro.start-date=$START_DATE \
    --macro.end-date=$END_DATE \
    --output bq \
    --bq.project=$GOOGLE_CLOUD_PROJECT \
    --bq.dataset=$BQ_DATASET \
    --logger $LOGGER
}

tag_landing_pages() {
  cd scripts
  python landings_score.py --dataset=$BQ_DATASET
  cd ..
}


generate_bq_views() {
  garf queries/sql/$1/*.sql \
    --source bq \
    --source.project-id=$GOOGLE_CLOUD_PROJECT \
    --macro.target_dataset=$BQ_DATASET \
    --macro.dataset=$BQ_DATASET \
    --logger $LOGGER
}

get_rsa() {
  garf queries/sql/input/rsa.sql \
    --source bq \
    --source.project-id=$GOOGLE_CLOUD_PROJECT \
    --macro.target_dataset=$BQ_DATASET \
    --macro.dataset=$BQ_DATASET \
    --output csv
}

_generate_placeholders() {
  echo 'CREATE TABLE IF NOT EXISTS `{dataset}.landing_page_relevance` AS (SELECT 0 AS campaign_id, "" AS url, 0.0 AS relevance_score LIMIT 0);' > /tmp/arba_landings.sql
  echo 'CREATE TABLE IF NOT EXISTS `{dataset}.usp` AS (SELECT "" AS identifier, "" AS content LIMIT 0);' > /tmp/arba_usp.sql
  echo 'CREATE TABLE IF NOT EXISTS `{dataset}.cta` AS (SELECT "" AS identifier, "" AS content LIMIT 0);' > /tmp/arba_cta.sql
  garf /tmp/arba_*.sql \
    --source bq --source.project_id=$GOOGLE_CLOUD_PROJECT --macro.dataset=$BQ_DATASET &> /dev/null
}

_process_rsa() {
  local prompt=$1
  local schema=$2
  local output=$3
  media-tagger describe \
    --db-uri $INTERNAL_V2_FILONOV_DB_URI \
    --input rsa.csv \
    --input.column-name=ad \
    --media-type text \
    --tagger gemini \
    --tagger.custom-prompt=$prompt \
    --tagger.custom-schema=$schema \
    --writer bq \
    --bq.project=$GOOGLE_CLOUD_PROJECT \
    --bq.dataset=$BQ_DATASET \
    --output $output \
    --logger $LOGGER
}

get_cta() {
  _process_rsa ./prompts/cta-prompt.txt ./prompts/boolean.json cta
}

get_usp() {
  _process_rsa ./prompts/usp-prompt.txt ./prompts/boolean.json usp
}

process_rsa() {
  get_rsa
  get_usp
  get_cta
  rm rsa.csv
}

fetch_ads_data
if [[ $TAGGING_ENABLED -eq 1 ]]; then
  tag_landing_pages
  process_rsa
else
  _generate_placeholders
fi
for step in 01 02 03; do
  echo "Run step $step"
  generate_bq_views $step
done
