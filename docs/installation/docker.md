# Docker

## Prerequisites

1.  Credentials for Google Ads API access which are stored in `google-ads.yaml`.
    See details [here](https://github.com/google/ads-api-report-fetcher/blob/main/docs/how-to-authenticate-ads-api.md).
2.  A Google Cloud project with billing account attached.
3.  [Vertex AI API](https://pantheon.corp.google.com/apis/library/aiplatform.googleapis.com) enabled.
4.  Environment variables specified:
    * [GEMINI_API_KEY](https://support.google.com/googleapi/answer/6158862?hl=en) to access Google Gemini.
5.  [Service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts#creating) created and [service account key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating) downloaded in order to write data to BigQuery.

    !!! note
        If authenticating via service account is not possible you can authenticate with the following command:
        ```
        gcloud auth application-default login
        ```
        You can grab `application_default_credentials.json` file from `$HOME/.config/gcloud` folder.

## Run

 Map local files, provide environment variables and run

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

## Customize

You can provide the following Environment variables to customize `arba` execution.

* `START_DATE` - First date of performance; can be either date (i.e. '2026-01-01') or lookback (`:YYYYMMDD-N`, where N - number of lookback days).
* `END_DATE` - Last date of performance in the same format as `START_DATE`.
* `MIN_COST_SHARE` - Share of text ads needs to be processed by Gemini. From 0 to 100.
* `GEMINI_API_KEY` - Gemini API key.
