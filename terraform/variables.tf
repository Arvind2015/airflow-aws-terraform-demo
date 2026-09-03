variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "dags_bucket_name" {
  description = "Globally unique name for the S3 bucket that holds Airflow DAG files"
  type        = string
}

variable "dags_prefix" {
  description = "Key prefix (folder) inside the bucket where DAGs are synced"
  type        = string
  default     = "dags"
}
