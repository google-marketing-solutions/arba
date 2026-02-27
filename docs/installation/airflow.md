# Apache Airflow

Running Arba in Apache Airflow is easy.

You'll need to provide three arguments for running `DockerOperator` inside your DAG:

* `/path/to/google-ads.yaml` - absolute path to `google-ads.yaml` file (can be remote)
* `service_account.json` - absolute path to service account json file

## Example DAGs

### Getting configuration files locally

!!!important
    Don't forget to change `/path/to/google-ads.yaml`, `path/to/service_account.json`
    valid paths.

```python
from airflow import DAG
from datetime import datetime, timedelta
from airflow.providers.docker.operators.docker import DockerOperator
from docker.types import Mount


default_args = {
    'description'           : 'arba',
    'depend_on_past'        : False,
    'start_date'            : datetime(2026, 3, 1),
    'email_on_failure'      : False,
    'email_on_retry'        : False,
    'retries'               : 1,
    'retry_delay'           : timedelta(minutes=5)
}
with DAG(
    'arba',
    default_args=default_args,
    schedule_interval="0 0 * * *",
    catchup=False) as dag:
    app_reporting_pack = DockerOperator(
      task_id='arba_docker',
      image='ghcr.io/google-marketing-solutions/arba:latest',
      api_version='auto',
      auto_remove=True,
      command=[
        "-c", "/google-ads.yaml",
        "-a", "GOOGLE_ADS_ACCOUNT",
      ],
      environment={
        'GEMINI_API_KEY': GEMINI_API_KEY,
        'GOOGLE_CLOUD_PROJECT': GOOGLE_CLOUD_PROJECT,
      },
      docker_url="unix://var/run/docker.sock",
      mounts=[
        Mount(
          source="/path/to/service_account.json",
          target="/app/service_account.json",
          type="bind"),
        Mount(
          source="/path/to/google-ads.yaml",
          target="/google-ads.yaml",
          type="bind"),
      ]
    )
```
