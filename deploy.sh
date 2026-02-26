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

if [[ -n "$GEMINI_API_KEY" ]]; then
  echo "GEMINI_API_KEY is set."
  while true; do
    read -p "Do you want to use it? (y/n) " yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* )
        read -p "Please enter the GEMINI_API_KEY: " GEMINI_API_KEY
        break;;
      * ) echo "Please answer yes or no.";;
    esac
  done
else
  read -p "Please enter the GEMINI_API_KEY: " GEMINI_API_KEY
fi

read -p "Please enter the Google Ads Account: " ACCOUNT

copy_googleads_config() {
  if ! gsutil ls gs://$PROJECT_ID > /dev/null 2> /dev/null; then
    echo "Creating GCS bucket gs://$PROJECT_ID"
    gsutil mb -b on gs://$PROJECT_ID
  fi
  echo 'Copying google-ads.yaml to GCS'
  if [[ -f ./google-ads.yaml ]]; then
    gsutil -h "Content-Type:text/plain" cp ./google-ads.yaml $GCS_BASE_PATH/google-ads.yaml
  elif [[ -f $HOME/google-ads.yaml ]]; then
    gsutil -h "Content-Type:text/plain" cp $HOME/google-ads.yaml $GCS_BASE_PATH/google-ads.yaml
  else
    echo "Please upload google-ads.yaml"
  fi
}

ADS_CONFIG=$GCS_BASE_PATH/google-ads.yaml

check_required_variables() {
  if [[ -z "$GEMINI_API_KEY" || -z "$ADS_CONFIG" || -z "$ACCOUNT" ]]; then
    echo -e "${RED}Please set GEMINI_API_KEY, ADS_CONFIG, and ACCOUNT variables in the script.${NC}"
    exit 1
  fi
}

create_registry() {
  REPO_EXISTS=$(gcloud artifacts repositories list --location=$LOCATION --filter="REPOSITORY=projects/'$PROJECT_ID'/locations/'$LOCATION'/repositories/'"$REPOSITORY"'" --format="value(REPOSITORY)" 2>/dev/null)
  if [[ ! -n $REPO_EXISTS ]]; then
    echo "Creating a repository in Artifact Registry"
    gcloud artifacts repositories create ${REPOSITORY} \
        --project=$PROJECT_ID \
        --repository-format=docker \
        --location=$LOCATION
    exitcode=$?
    if [ $exitcode -ne 0 ]; then
      echo -e "${RED}[ ! ] Please upgrade Cloud SDK to the latest version: gcloud components update${NC}"
    fi
  fi
}

check_owners() {
  local project_admins=$(gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings" \
    --filter="bindings.role=roles/owner OR bindings.role=roles/admin" \
    --format="value(bindings.members[])"
  )
  if [[ ! $project_admins =~ $USER_EMAIL ]]; then
      echo -e "${RED}User $USER_EMAIL does not have admin / owner rights to project $PROJECT_ID${NC}"
      exit
  fi
}

check_billing() {
  BILLING_ENABLED=$(gcloud beta billing projects describe $PROJECT_ID --format="csv(billingEnabled)" | tail -n 1)
  if [[ "$BILLING_ENABLED" = 'False' ]]
  then
    echo -e "${RED}The project $PROJECT_ID does not have a billing enabled. Please activate billing${NC}"
    exit -1
  fi
}

enable_apis() {
  echo "Enabling APIs"
  gcloud services enable \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    cloudscheduler.googleapis.com \
    logging.googleapis.com \
    artifactregistry.googleapis.com \
    googleads.googleapis.com \
    bigquery.googleapis.com \
    aiplatform.googleapis.com \
    generativelanguage.googleapis.com
}

set_iam_permissions() {
  required_roles="run.invoker run.admin iam.serviceAccountUser"
  echo "Setting up IAM permissions"
  for role in $required_roles; do
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member=serviceAccount:$SERVICE_ACCOUNT \
      --role=roles/$role \
      --condition=None \
      --no-user-output-enabled
  done
}

deploy() {
  echo "Deploying Cloud Run job"
  gcloud run jobs deploy ${APP_NAME} \
    --image $IMAGE --region $LOCATION  --project $PROJECT_ID \
    --task-timeout=1h \
    --max-retries=1 \
    --cpu=2 \
    --memory=4Gi \
    --set-env-vars GOOGLE_CLOUD_PROJECT=$PROJECT_ID,GEMINI_API_KEY=$GEMINI_API_KEY \
    --args="-d","$DATASET","-l","gcloud","-a","$ACCOUNT","-c","$ADS_CONFIG"
}

enable_telemetry_apis() {
  gcloud services enable \
    monitoring.googleapis.com \
    cloudtrace.googleapis.com \
    telemetry.googleapis.com
}

add_telemetry_roles() {
  telemetry_roles="cloudtrace.agent monitoring.metricWriter"
  echo "Adding telemetry roles"
  for role in $telemetry_roles; do
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member=serviceAccount:$SERVICE_ACCOUNT \
      --role=roles/$role \
      --condition=None \
      --no-user-output-enabled
  done
}

enable_telemetry() {
  enable_telemetry_apis
  add_telemetry_roles

  gcloud run jobs update ${APP_NAME} --region $LOCATION \
    --update-env-vars OTEL_EXPORTER_GCP_PROJECT_ID=$PROJECT_ID,OTEL_EXPORTER_OTLP_ENDPOINT=https://telemetry.googleapis.com:443
}

ask_telemetry() {
  while true; do
    read -p "Do you want to enable Cloud Telemetry? (y/n) " yn
    case $yn in
        [Yy]* ) enable_telemetry; break;;
        [Nn]* ) echo "Skipping telemetry setup."; break;;
        * ) echo "Please answer yes or no.";;
    esac
  done
}

schedule() {
  SCHEDULER_JOB_NAME="${APP_NAME}-scheduler"
  echo "Setting up Cloud Scheduler job to run at midnight"
  if gcloud scheduler jobs describe $SCHEDULER_JOB_NAME --location=$LOCATION >/dev/null 2>&1; then
    echo "Updating existing Cloud Scheduler job: $SCHEDULER_JOB_NAME"
    gcloud scheduler jobs update http $SCHEDULER_JOB_NAME \
      --location=$LOCATION \
      --schedule="0 0 * * *" \
      --uri="https://run.googleapis.com/v2/projects/$PROJECT_ID/locations/$LOCATION/jobs/${APP_NAME}:run" \
      --http-method=POST \
      --oauth-service-account-email=${SERVICE_ACCOUNT}
  else
    echo "Creating new Cloud Scheduler job: $SCHEDULER_JOB_NAME"
    gcloud scheduler jobs create http $SCHEDULER_JOB_NAME \
      --location=$LOCATION \
      --schedule="0 0 * * *" \
      --uri="https://run.googleapis.com/v2/projects/$PROJECT_ID/locations/$LOCATION/jobs/${APP_NAME}:run" \
      --http-method=POST \
      --oauth-service-account-email=${SERVICE_ACCOUNT}
  fi
}

deploy_arba() {
  echo "Starting ARBA deployment process"
  check_required_variables
  check_owners
  check_billing
  enable_apis
  create_registry
  set_iam_permissions
  copy_googleads_config
  build
  deploy
  ask_telemetry
  schedule
  echo "Deployment process finished successfully!"
}

deploy_arba
