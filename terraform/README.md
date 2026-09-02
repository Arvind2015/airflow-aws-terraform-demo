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

## What it creates

| Resource | Purpose |
| --- | --- |
| `aws_s3_bucket.dags` (+ versioning, AES256, public-access block) | Holds the DAG `.py` files under the `dags/` prefix |

---

## One-time setup (do this once, before either use case)

1. **AWS credentials for CI.** In the AWS console create an IAM user with rights
   to manage S3 (for a demo, attach `PowerUserAccess`). Generate an access key.

2. **Terraform state bucket.** Pick a globally-unique name, put it in
   `backend.tf` (replace `airflow-tf-state-CHANGE-ME`), then create it:

   ```bash
   aws s3 mb s3://<your-tf-state-bucket> --region us-east-1
   aws s3api put-bucket-versioning --bucket <your-tf-state-bucket> \
     --versioning-configuration Status=Enabled
   ```

3. **GitHub repo config** (repo → Settings → Secrets and variables → Actions):

   | Tab | Name | Value |
   | --- | --- | --- |
   | Secrets | `AWS_ACCESS_KEY_ID` | from step 1 |
   | Secrets | `AWS_SECRET_ACCESS_KEY` | from step 1 |
   | Variables | `AWS_REGION` | e.g. `us-east-1` |
   | Variables | `DAGS_BUCKET` | globally-unique name for the DAGs bucket |

That's the whole setup. Nothing here is repeated per merge.

---

## Use case A — GitHub Actions runs Terraform

Nothing to run by hand. `.github/workflows/deploy.yml`:

- **On a pull request** touching `terraform/**` or `dags/**` → `terraform plan`,
  posted as a PR comment. No changes applied.
- **On merge to `main`** → `terraform apply` → then `aws s3 sync dags/` into the
  bucket.

`.github/workflows/release.yml` separately creates a semantic-version tag +
GitHub Release on each merge to `main` (Conventional Commit messages drive the
bump: `feat:` = minor, `fix:` = patch).

## Use case B — run Terraform locally

```bash
cd terraform
aws configure                          # your AWS account
cp terraform.tfvars.example terraform.tfvars   # set dags_bucket_name (same as DAGS_BUCKET)

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Because the state bucket in `backend.tf` is the same one CI uses, a local
`apply` and a CI `apply` see the same state — don't run both at the same moment.

---

## Files

| File | |
| --- | --- |
| `backend.tf` | S3 remote state config (shared by local + CI) |
| `providers.tf` | Terraform + AWS provider versions, default tags |
| `variables.tf` | `aws_region`, `dags_bucket_name`, `dags_prefix` |
| `main.tf` | the DAGs S3 bucket |
| `outputs.tf` | bucket name + `s3://` URI |
| `terraform.tfvars.example` | copy to `terraform.tfvars` for local runs |

`terraform.tfvars` and `*.tfstate` are gitignored (root `.gitignore`).
`.terraform.lock.hcl` should be committed.
