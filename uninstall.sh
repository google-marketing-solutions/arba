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

set -e
source ./common.sh

init_project_id
init_common_variables

delete_image() {
  if gcloud artifacts docker images list $IMAGE --quiet &> /dev/null; then
    gcloud artifacts docker images delete $IMAGE
  fi
}

delete_googleads_config() {
  gsutil rm -rf $GCS_BASE_PATH

}
remove_job() {
  gcloud run jobs delete ${APP_NAME} \
    --region $LOCATION  --project $PROJECT_ID --quiet
}

remove_schedule() {
  SCHEDULER_JOB_NAME="${APP_NAME}-scheduler"
  gcloud scheduler jobs delete $SCHEDULER_JOB_NAME --location $LOCATION --quiet
}

remove() {
  check_installation
  echo "Removing ARBA deployment"
  delete_googleads_config
  delete_image
  remove_job
  remove_schedule
  echo "ARBA has been removed from project" $PROJECT_ID
}

remove
