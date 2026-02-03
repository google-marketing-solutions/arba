# Arba - AdRank Booster

Ad Rank Booster helps win the search auction thanks to quality score improvement
opposed to bidding levers.
Improving such components as landing page experience, ad relevance and expected
CTR significantly uplifts their performance and serves a foundation to grow search investment.

## Deliverable

Looker Studio dashboard with recommendations on improving performance of search campaigns.

## Deployment

### Prerequisites

1. Credentials for Google Ads API access which stored in `google-ads.yaml`.
   See details [here](https://github.com/google/ads-api-report-fetcher/blob/main/docs/how-to-authenticate-ads-api.md).
1. A Google Cloud project with billing account attached.

### Installation

```
pip install -r requirements.txt
```

### Usage

Provide default values in `workflow-config.yaml`

* `bq_project` - name of Google Cloud Project.
* `google_ads_account` - ID(s) of Google Ads accounts .

Optionally you can provide other parameters:

* `bq_dataset` - name of BigQuery dataset where the AdRank Booster data to be stored (by default `arba`).
* `google_ads_config` -  path to `google-ads.yaml` file (by default expected in your home directory).

Run the following command to start generating data:

```
garf -w workflow-config.yaml
```

### Run in Docker

1. Build image

```
docker build -t arba .
```

2. Run

```
docker run \
  -v /path/to/google-ads.yaml:/app/google-ads.yaml \
  -v /path/to/application_default_credentials.json:/app/service_account.json \
  -e GEMINI_API_KEY=$GEMINI_API_KEY \
  -e GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT \
  arba -a <GOOGLE_ADS_ACCOUNT> -c /app/google-ads.yaml
```


## Disclaimer
This is not an officially supported Google product. This project is not
eligible for the [Google Open Source Software Vulnerability Rewards
Program](https://bughunters.google.com/open-source-security).
