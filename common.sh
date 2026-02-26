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

# Colors
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
LOCATION=us-central1
REPOSITORY=google-marketing-solutions
DATASET=arba
IMAGE_NAME=arba
APP_NAME=arba

init_project_id() {
  if [[ -n "$GOOGLE_CLOUD_PROJECT" ]]; then
    echo "Current project is set to $GOOGLE_CLOUD_PROJECT."
    while true; do
      read -p "Do you want to use it? (y/n) " yn
      case $yn in
        [Yy]* ) PROJECT_ID=$GOOGLE_CLOUD_PROJECT; break;;
        [Nn]* )
          read -p "Please enter the Google Cloud Project ID: " PROJECT_ID
          break;;
        * ) echo "Please answer yes or no.";;
      esac
    done
  else
    read -p "Please enter the Google Cloud Project ID: " PROJECT_ID
  fi
  export PROJECT_ID
}

init_common_variables() {
  if [[ -z "$PROJECT_ID" ]]; then
      echo "Project ID not set. Please call init_project_id first."
      exit 1
  fi

  PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="csv(projectNumber)" | tail -n 1)
  SERVICE_ACCOUNT=$PROJECT_NUMBER-compute@developer.gserviceaccount.com
  USER_EMAIL=$(gcloud config get-value account)

  GCS_BASE_PATH=gs://$PROJECT_ID/$APP_NAME
  IMAGE=${LOCATION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}
}

build() {
  echo "Building and submitting image to Cloud Build"
  gcloud builds submit --tag $IMAGE --project $PROJECT_ID
}

check_installation() {
  if gcloud run jobs describe ${APP_NAME} --region=$LOCATION --project=$PROJECT_ID > /dev/null 2>&1; then
    echo "arba job exists"
  else
    echo -e "${RED}[ ! ] Arba not installed. Run ./deploy.sh to perform installation.${NC}"
    exit 1
  fi
}
