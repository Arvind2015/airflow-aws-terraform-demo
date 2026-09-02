# Remote state, shared by:
#   - local runs  (Use case B: you run `terraform apply` from your machine)
#   - CI runs      (Use case A: GitHub Actions runs `terraform apply` on merge to main)
#
# Both must point at the same bucket/key so they operate on one state.
#
# ONE-TIME SETUP before the first `terraform init`:
#   aws s3 mb s3://airflow-tf-state-CHANGE-ME --region us-east-1
#   aws s3api put-bucket-versioning --bucket airflow-tf-state-CHANGE-ME \
#     --versioning-configuration Status=Enabled
#
# Bucket names are not secret, so it is fine to commit this.
terraform {
  backend "s3" {
    bucket       = "airflow-tf-state-CHANGE-ME"
    key          = "airflow-dags/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # native S3 state locking (Terraform >= 1.11); no DynamoDB table needed
  }
}
