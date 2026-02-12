# Copyright 2026 Google LLC
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
    echo "Usage: $0 -d <dataset> -t <tagging_enabled> -l <logger_type>"
    exit 1
}
WORKFLOW=/app/workflow-config.yaml
BQ_PROJECT=mena-youtube-reach-planner
MIN_COST_SHARE=80
START_DATE=:YYYYMMDD-31
END_DATE=:YYYYMMDD-1
LOG_NAME=arba

while getopts "a:c:d:t:w:l:" opt; do
    case $opt in
        a) ACCOUNT="$OPTARG" ;;
        c) ADS_CONFIG="$OPTARG" ;;
        d) BQ_DATASET="$OPTARG" ;;
        t) TAGGING_ENABLED="$OPTARG" ;;
        w) WORKFLOW="$OPTARG" ;;
        l) LOGGER="$OPTARG" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done
if [ -z "$LOGGER" ]; then
  LOGGER='local'
fi
if [ -z "$TAGGING_ENABLED" ]; then
  TAGGING_ENABLED=0
else
  TAGGING_ENABLED=1
fi

run_bq() {
  local account=$1
  local dataset=$2
  if [ -z "$dataset" ]; then
    local arba_dataset='arba'
  else
    local arba_dataset=${dataset}
  fi
  garf -w $WORKFLOW \
    --workflow-include googleads \
    --logger $LOGGER --log-name $LOG_NAME \
    --source.account=$account \
    --source.path-to-config=$ADS_CONFIG \
    --macro.start_date=$START_DATE --macro.end_date=$END_DATE \
    --output bq \
    --bq.project=$BQ_PROJECT --bq.dataset=${arba_dataset}

  cd scripts
  python landings_score.py --dataset=${arba_dataset} \
    --log-name=$LOG_NAME --logger $LOGGER
  cd ..
  garf -w $WORKFLOW \
    --workflow-include bq_input \
    --logger $LOGGER --log-name $LOG_NAME \
    --macro.dataset=${arba_dataset} --macro.target_dataset=${arba_dataset} \
    --source.project=$BQ_PROJECT

  garf -w $WORKFLOW \
    --workflow-include tagging \
    --logger $LOGGER --log-name $LOG_NAME \
    --macro.dataset=${arba_dataset} --macro.target_dataset=${arba_dataset} \
    --macro.cost_share=$MIN_COST_SHARE \
    --output bq \
    --bq.project=$BQ_PROJECT --bq.dataset=${arba_dataset} \
    --source.project=$BQ_PROJECT

  garf -w $WORKFLOW \
    --workflow-skip googleads,bq_input,empty_bq,tagging \
    --logger $LOGGER --log-name $LOG_NAME \
    --macro.dataset=${arba_dataset} --macro.target_dataset=${arba_dataset} \
    --source.project=$BQ_PROJECT
}
run_bq $ACCOUNT $BQ_DATASET
