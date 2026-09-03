# Remote state, shared by:
#   - local runs  (Use case B: you run `terraform apply` from your machine)
#   - CI runs      (Use case A: GitHub Actions runs `terraform apply` on merge to main)
#
# Both must point at the same bucket/key so they operate on one state.
#
# ONE-TIME SETUP before the first `terraform init`:
#   aws s3 mb s3://prism-airflow-tf-state --region eu-west-1
#   aws s3api put-bucket-versioning --bucket prism-airflow-tf-state \
#     --versioning-configuration Status=Enabled
#
# Bucket names are not secret, so it is fine to commit this.
terraform {
  backend "s3" {
    bucket       = "prism-airflow-tf-state"
    key          = "airflow-dags/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true # native S3 state locking (Terraform >= 1.11); no DynamoDB table needed
  }
}
