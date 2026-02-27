# Local Installation

## Prerequisites

1.  Credentials for Google Ads API access which are stored in `google-ads.yaml`.
    See details [here](https://github.com/google/ads-api-report-fetcher/blob/main/docs/how-to-authenticate-ads-api.md).
2.  A Google Cloud project with billing account attached.
3.  [Vertex AI API](https://pantheon.corp.google.com/apis/library/aiplatform.googleapis.com) enabled.
4.  Environment variables specified:
    * [GEMINI_API_KEY](https://support.google.com/googleapi/answer/6158862?hl=en) to access Google Gemini.
5.  [Service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts#creating) created and [service account key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating) downloaded in order to write data to BigQuery.
    * Expose `GOOGLE_APPLICATION_CREDENTIALS` variable that points to this service account JSON file.

    !!! note
        If authenticating via service account is not possible you can authenticate with the following command:
        ```
        gcloud auth application-default login
        ```
        You can grab `application_default_credentials.json` file from `$HOME/.config/gcloud` folder.

## Install


```
pip install -r requirements.txt
```

## Run

1.  Provide default values in `workflow-config.yaml`
    * `bq_project` - name of Google Cloud Project.
    * `google_ads_account` - ID(s) of Google Ads accounts.

!!!note
    Optionally you can provide other parameters:

    * `bq_dataset` - name of BigQuery dataset where the AdRank Booster data to be stored (by default `arba`).
    * `google_ads_config` -  path to `google-ads.yaml` file (by default expected in your home directory).

2.  Run the following command to start generating data:

```
garf -w workflow-config.yaml
```
