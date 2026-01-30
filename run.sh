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
    echo "Usage: $0 -d <dataset> -t <tagging_enabled> -l <logger_type>"
    exit 1
}

while getopts "d:t:w:l:" opt; do
    case $opt in
        d) BQ_DATASET="$OPTARG" ;;
        t) TAGGING_ENABLED="$OPTARG" ;;
        w) WORKFLOW="$OPTARG" ;;
        l) LOGGER="$OPTARG" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done
if [ -z "$LOGGER" ]; then
  LOGGER='rich'
fi
if [ -z "$TAGGING_ENABLED" ]; then
  TAGGING_ENABLED=0
else
  TAGGING_ENABLED=1
fi

tag_landing_pages() {
  cd scripts
  python landings_score.py --dataset=$BQ_DATASET
  cd ..
}
if [[ $TAGGING_ENABLED -eq 1 ]]; then
  garf -w $WORKFLOW --workflow-include googleads --logger $LOGGER
  tag_landing_pages
  garf -w $WORKFLOW --workflow-skip googleads,empty_bq --logger $LOGGER
else
  garf -w $WORKFLOW
fi
