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

gaarf queries/ads/*.sql \
	--account $GOOGLE_ADS_ACCOUNT \
	--customer-id-query 'SELECT customer.id FROM campaign WHERE campaign.advertising_channel_type = SEARCH' \
	--macro.start-date=:YYYYMMDD-30 \
	--macro.end-date=:YYYYMMDD-1 \
	--output bq \
	--bq.project=$GOOGLE_CLOUD_PROJECT \
	--bq.dataset=arba


gaarf-bq queries/sql/views/*.sql \
	--project=$GOOGLE_CLOUD_PROJECT \
	--macro.target_dataset=arba_output \
	--macro.dataset=arba
