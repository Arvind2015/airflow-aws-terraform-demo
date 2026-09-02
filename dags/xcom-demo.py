from airflow import DAG
from airflow.providers.standard.operators.python import PythonOperator
from datetime import datetime


def get_employee():
    employee_id = "EMP123"
    print(f"Found employee: {employee_id}")
    return employee_id


def provision_employee(ti):
    employee_id = ti.xcom_pull(task_ids="get_employee")

    print(f"Received employee ID from XCom: {employee_id}")
    print(f"Provisioning employee: {employee_id}")


with DAG(
    dag_id="xcom_demo",
    start_date=datetime(2026, 8, 22),
    schedule=None,
    catchup=False,
) as dag:

    get_employee_task = PythonOperator(
        task_id="get_employee",
        python_callable=get_employee,
    )

    provision_employee_task = PythonOperator(
        task_id="provision_employee",
        python_callable=provision_employee,
    )

    get_employee_task >> provision_employee_task