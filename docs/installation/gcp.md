# Google Cloud Platform

Arba is deployed to Google Cloud as a Cloud Run job.

During the installation the following artifacts are created:

* Cloud Run job (`arba`)
* Cloud Scheduler job (`arba-scheduler`)
* Bucket in Cloud Storage - `gs://PROJECT_ID/arba`)
* Repository in Artifact Registry - `google-marketing-solutions`
* Image in the repository above - `arba`

## Prerequisites

1.  Credentials for Google Ads API access which stored in `google-ads.yaml`.
    See details [here](https://github.com/google/ads-api-report-fetcher/blob/main/docs/how-to-authenticate-ads-api.md).
2.  A Google Cloud project with billing account attached.
3.  [Vertex AI API](https://pantheon.corp.google.com/apis/library/aiplatform.googleapis.com) enabled.
4.  Environment variables specified:
    * [GEMINI_API_KEY](https://support.google.com/googleapi/answer/6158862?hl=en) to access Google Gemini.

## Install

1.  Clone repo in Cloud Shell or on your local machine (we assume Linux with `gcloud` CLI installed):

    ```bash
    git clone https://github.com/google-marketing-solutions/arba.git
    ```

2.  Go to the repo folder: `cd arba/`

3.  Put your `google-ads.yaml` there.

4.  Deploy


```bash
./deploy.sh
```

## Customize

`arba` is deployed as a Cloud Run job with name `arba`.

You can customize the following options of the job.

In Google Cloud go to `Cloud Run -> Jobs -> arba`, click on `View & edit job configuration`,
scroll to `Containers, Connection, Security`, select `Variables & Secrets` and
adjust one of the following Environment variables:

* `BQ_DATASET` - BigQuery dataset where data are saved.
* `ACCOUNT` - Google Ads account(s) or MCC(s).
* `ADS_CONFIG` - Path to google-ads.yaml on Google Cloud Storage.
* `START_DATE` - First date of performance; can be either date (i.e. '2026-01-01') or lookback (`:YYYYMMDD-N`, where N - number of lookback days).
* `END_DATE` - Last date of performance in the same format as `START_DATE`.
* `MIN_COST_SHARE` - Share of text ads needs to be processed by Gemini. From 0 to 100.
* `GEMINI_API_KEY` - Gemini API key.

By default `arba` is scheduled to run on midnight UTC.
You can change the schedule in Cloud Scheduler. Locate `arba-scheduler` and define your own schedule.

## Upgrade

Upgrade makes new queries and dependencies available.

```bash
./upgrade.sh
```

## Uninstall

Uninstall removes Arba Cloud Storage bucket, docker image, Cloud Run Job and Cloud Scheduler only.
You need to remove BigQuery dataset manually.

```bash
./uninstall.sh
```
