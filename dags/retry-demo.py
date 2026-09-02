from airflow import DAG
from airflow.providers.standard.operators.python import PythonOperator
from datetime import datetime, timedelta


def unreliable_task(**context):
    ti = context["ti"]

    print(f"Airflow try number: {ti.try_number}")

    if ti.try_number == 1:
        raise Exception("Temporary provisioning failure")

    print("Provisioning succeeded!")


with DAG(
    dag_id="retry_demo",
    start_date=datetime(2026, 8, 22),
    schedule=None,
    catchup=False,
) as dag:

    provision_task = PythonOperator(
        task_id="provision_user",
        python_callable=unreliable_task,
        retries=2,
        retry_delay=timedelta(seconds=30),
    )