from airflow import DAG
from airflow.providers.standard.operators.python import PythonOperator
from datetime import datetime


def extract():
    print("Extracting data")


def transform():
    print("Transforming data")


def load():
    print("Loading data")


with DAG(
    dag_id="mwaa_demo",
    start_date=datetime(2026, 8, 22),
    schedule=None,
    catchup=False,
) as dag:

    extract_task = PythonOperator(
        task_id="extract",
        python_callable=extract,
    )

    transform_task = PythonOperator(
        task_id="transform",
        python_callable=transform,
    )

    load_task = PythonOperator(
        task_id="load",
        python_callable=load,
    )

    extract_task >> transform_task >> load_task