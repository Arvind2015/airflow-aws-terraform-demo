# Single-environment demo: values are hardcoded here as defaults so the config
# is self-contained (no GitHub Variables, no tfvars needed). Override per run
# with -var / TF_VAR_* / terraform.tfvars if you ever need to.

variable "aws_region" {
  description = "AWS region for the DAGs bucket. MUST match region in backend.tf."
  type        = string
  default     = "eu-west-1"
}

variable "dags_bucket_name" {
  description = "Name of the S3 bucket that holds Airflow DAG files"
  type        = string
  default     = "prism-dags"
}

variable "dags_prefix" {
  description = "Key prefix (folder) inside the bucket where DAGs are synced"
  type        = string
  default     = "dags"
}
