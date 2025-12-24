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
    echo "Usage: $0 -d <dataset> -p <project> -a <ads-config> -s <start_date> -e <end_date> -c <account>"
    exit 1
}

while getopts "d:p:a:s:e:m:c:" opt; do
    case $opt in
        d) BQ_DATASET="$OPTARG" ;;
        p) GOOGLE_CLOUD_PROJECT="$OPTARG" ;;
        a) ADS_CONFIG="$OPTARG" ;;
        s) START_DATE="$OPTARG" ;;
        e) END_DATE="$OPTARG" ;;
        c) GOOGLE_ADS_ACCOUNT="$OPTARG" ;;
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

fetch_ads_data() {
  gaarf queries/ads/*.sql \
    --account $GOOGLE_ADS_ACCOUNT \
    --ads-config $ADS_CONFIG \
    --customer-id-query 'SELECT customer.id FROM campaign WHERE campaign.advertising_channel_type = SEARCH' \
    --macro.start-date=$START_DATE \
    --macro.end-date=$END_DATE \
    --output bq \
    --bq.project=$GOOGLE_CLOUD_PROJECT \
    --bq.dataset=$BQ_DATASET
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
    --macro.dataset=$BQ_DATASET
}

fetch_ads_data
tag_landing_pages
for step in 01 02 03; do
  echo "Run step $step"
  generate_bq_views $step
done
