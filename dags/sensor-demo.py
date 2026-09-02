from airflow import DAG
from airflow.providers.standard.sensors.python import PythonSensor
from airflow.providers.standard.operators.python import PythonOperator
from datetime import datetime


def check_employee_ready():
    print("Checking whether employee data is ready...")
    return True


def process_employee():
    print("Processing employee provisioning...")


with DAG(
    dag_id="iam_sensor_demo",
    start_date=datetime(2026, 8, 22),
    schedule=None,
    catchup=False,
) as dag:

    wait_for_employee = PythonSensor(
        task_id="wait_for_employee",
        python_callable=check_employee_ready,
        poke_interval=10,
        timeout=60,
    )

    process = PythonOperator(
        task_id="process_employee",
        python_callable=process_employee,
    )

    wait_for_employee >> process