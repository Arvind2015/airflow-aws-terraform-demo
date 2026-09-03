# Terraform — DAG deployment infrastructure

Provisions the S3 bucket that holds the Airflow DAG files. **No Airflow / MWAA
environment is created** (that costs money); the demo stops at "DAG files land in
an S3 folder".

The exact same Terraform code is run two ways:

| | Use case A | Use case B |
| --- | --- | --- |
| Who runs `terraform apply` | GitHub Actions, on merge to `main` | You, from your laptop |
| Auth to AWS | `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` GitHub Secrets | your local `aws configure` credentials |
| Workflow | `.github/workflows/deploy.yml` | manual commands below |

Both share the **same remote state** (S3 backend in `backend.tf`), so they act on
one set of infrastructure.

Region (`eu-west-1`) and bucket names are hardcoded in the config — see
`variables.tf` and `backend.tf`. This is a single-environment demo; multi-env is
deferred.

## What it creates

| Resource | Purpose |
| --- | --- |
| `aws_s3_bucket.dags` (+ versioning, AES256, public-access block) | Holds the DAG `.py` files under the `dags/` prefix |

---

## One-time setup (do this once, before either use case)

1. **AWS credentials for CI.** In the AWS console create an IAM user with rights
   to manage S3 (for a demo, attach `PowerUserAccess`). Generate an access key.

2. **Terraform state bucket.** Already created for this demo as
   `prism-airflow-tf-state` (see `backend.tf`). To recreate from scratch:

   ```bash
   aws s3 mb s3://prism-airflow-tf-state --region eu-west-1
   aws s3api put-bucket-versioning --bucket prism-airflow-tf-state \
     --versioning-configuration Status=Enabled
   ```

3. **GitHub repo Secrets** (repo → Settings → Secrets and variables → Actions →
   Secrets):

   | Name | Value |
   | --- | --- |
   | `AWS_ACCESS_KEY_ID` | from step 1 |
   | `AWS_SECRET_ACCESS_KEY` | from step 1 |

   No repo Variables are needed — region and bucket name live in the Terraform
   config and `deploy.yml`.

That's the whole setup. Nothing here is repeated per merge.

---

## Use case A — GitHub Actions runs Terraform

Nothing to run by hand. `.github/workflows/deploy.yml`:

- **On a pull request** touching `terraform/**` or `dags/**` → `terraform plan`,
  posted as a PR comment. No changes applied.
- **On merge to `main`** → `terraform apply` → then `aws s3 sync dags/` into the
  bucket (the sync step reads the bucket name from `terraform output`).

`.github/workflows/release.yml` separately creates a semantic-version tag +
GitHub Release on each merge to `main` (Conventional Commit messages drive the
bump: `feat:` = minor, `fix:` = patch).

## Use case B — run Terraform locally

```bash
cd terraform
aws configure          # your AWS account

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

No `terraform.tfvars` needed — `variables.tf` has working defaults. Because the
state bucket in `backend.tf` is the same one CI uses, a local `apply` and a CI
`apply` see the same state — don't run both at the same moment.

---

## Files

| File | |
| --- | --- |
| `backend.tf` | S3 remote state config (shared by local + CI) |
| `providers.tf` | Terraform + AWS provider versions, default tags |
| `variables.tf` | `aws_region`, `dags_bucket_name`, `dags_prefix` — all with defaults |
| `main.tf` | the DAGs S3 bucket |
| `outputs.tf` | bucket name + `s3://` URI |
| `terraform.tfvars.example` | optional local overrides |

`terraform.tfvars` and `*.tfstate` are gitignored (root `.gitignore`).
`.terraform.lock.hcl` should be committed.
