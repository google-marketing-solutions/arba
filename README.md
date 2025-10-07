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

```
export GOOGLE_ADS_ACCOUNT=
bash run.sh
```

## Disclaimer
This is not an officially supported Google product.
