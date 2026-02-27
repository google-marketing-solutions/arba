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

where:
  * `-a` - Google Ads account(s) or MCC(s)
  * `-c` - Path to google-ads.yaml

#### Customize

You can provide the following ENV variables to customize `arba` execution.

* `START_DATE` - First date of performance; can be either date (i.e. '2026-01-01') or lookback (`:YYYYMMDD-N`, where N - number of lookback days).
* `END_DATE` - Last date of performance in the same format as `START_DATE`.
* `MIN_COST_SHARE` - Share of text ads needs to be processed by Gemini. From 0 to 100.
* `GEMINI_API_KEY` - Gemini API key.

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

#### Customize

`arba` is deploy as a Cloud Run job with name `arba`.

You can customize the following options of the job.

In Google Cloud go to `Cloud Run -> Jobs -> arba`, click on `View & edit job configuration`,
scroll to `Containers, Connection, Security`, select `Variables & Secrets` and
adjust one of the following ENV variables:

* `BQ_DATASET` - BigQuery dataset where data are saved.
* `ACCOUNT` - Google Ads account(s) or MCC(s).
* `ADS_CONFIG` - Path to google-ads.yaml on Google Cloud Storage.
* `START_DATE` - First date of performance; can be either date (i.e. '2026-01-01') or lookback (`:YYYYMMDD-N`, where N - number of lookback days).
* `END_DATE` - Last date of performance in the same format as `START_DATE`.
* `MIN_COST_SHARE` - Share of text ads needs to be processed by Gemini. From 0 to 100.
* `GEMINI_API_KEY` - Gemini API key.

By default `arba` is scheduled to run on midnight UTC.
You can change the schedule in Cloud Scheduler. Locate `arba-scheduler` and define your own schedule.

#### Upgrade

Upgrade make new queries and dependencies available.

```bash
./upgrade.sh
```

#### Uninstall

Uninstall removes Arba Cloud Storage bucker, docker image, Cloud Run Job and Cloud Scheduler only.
You need to remove BigQuery dataset manually.

```bash
./uninstall.sh
```

## Create dashboard

Provide BigQuery project and dataset names where `arba` data are located.

```
./scripts/create_dashboard.sh -p $GOOGLE_CLOUD_PROJECT -d arba
```


## Disclaimer
This is not an officially supported Google product. This project is not
eligible for the [Google Open Source Software Vulnerability Rewards
Program](https://bughunters.google.com/open-source-security).
