# Arba - AdRank Booster

Ad Rank Booster helps win the search auction thanks to quality score improvement
opposed to bidding levers.
Improving such components as landing page experience, ad relevance and expected
CTR significantly uplifts their performance and serves a foundation to grow search investment.

## Deliverable

Looker Studio [dashboard](https://lookerstudio.google.com/c/reporting/c575864a-90d1-4431-84e2-ca1bb8de294a/page/6EJaF) with recommendations on improving performance of search campaigns.

> [!IMPORTANT]
> Join [`arba-readers-external`](https://groups.google.com/g/arba-readers-external) Google group  to get access to the [dashboard template](https://lookerstudio.google.com/c/reporting/c575864a-90d1-4431-84e2-ca1bb8de294a/page/6EJaF).

## Deployment

### Prerequisites

1. Credentials for Google Ads API access which stored in `google-ads.yaml`.
   See details [here](https://github.com/google/ads-api-report-fetcher/blob/main/docs/how-to-authenticate-ads-api.md).
1. A Google Cloud project with billing account attached.
1. [Vertex AI API](https://pantheon.corp.google.com/apis/library/aiplatform.googleapis.com) enabled.
1.  Environmental variables specified:
  * [Gemini API key](https://support.google.com/googleapi/answer/6158862?hl=en) to access to access Google Gemini.

    ```bash
    export GEMINI_API_KEY=<YOUR_API_KEY_HERE>
    ```

  * `GOOGLE_CLOUD_PROJECT` - points the Google Cloud project with Vertex AI API enabled.
    ```
    export GOOGLE_CLOUD_PROJECT=<YOUR_PROJECT_HERE>
    ```


### Run locally


1. Install dependencies

```
pip install -r requirements.txt
```

2. Provide default values in `workflow-config.yaml`


* `bq_project` - name of Google Cloud Project.
* `google_ads_account` - ID(s) of Google Ads accounts .

Optionally you can provide other parameters:

* `bq_dataset` - name of BigQuery dataset where the AdRank Booster data to be stored (by default `arba`).
* `google_ads_config` -  path to `google-ads.yaml` file (by default expected in your home directory).

3. Run the following command to start generating data:

```
garf -w workflow-config.yaml
```

### Run in Docker

1. Map local files, provide environmental variables and run

```
docker run \
  -v /path/to/google-ads.yaml:/app/google-ads.yaml \
  -v /path/to/application_default_credentials.json:/app/service_account.json \
  -e GEMINI_API_KEY=$GEMINI_API_KEY \
  -e GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT \
  ghcr.io/google-marketing-solutions/arba:latest \
  -a <GOOGLE_ADS_ACCOUNT> -c /app/google-ads.yaml
```

### Deploy to Google Cloud

1. Clone repo in Cloud Shell or on your local machine (we assume Linux with `gcloud` CLI installed):

```bash
git clone https://github.com/google-marketing-solutions/arba.git
```

1. Go to the repo folder: `cd arba/`

1. Put your `google-ads.yaml` there.

1. Deploy


```bash
./deploy.sh
```

## Create dashboard

Provide BigQuery project and dataset names where `arba` data are located.

```
./scripts/create_dashboard -p $GOOGLE_CLOUD_PROJECT -d arba
```


## Disclaimer
This is not an officially supported Google product. This project is not
eligible for the [Google Open Source Software Vulnerability Rewards
Program](https://bughunters.google.com/open-source-security).
