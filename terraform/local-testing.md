# Local Terraform testing (Use case B)

Running the same `terraform/` config from your laptop instead of GitHub Actions.

## Prerequisites (one-time)

```powershell
# Terraform >= 1.11 (needed for use_lockfile in backend.tf)
choco install terraform -y          # or manual install to %LOCALAPPDATA%\terraform
terraform version

# AWS credentials in C:\Users\<you>\.aws\
#   credentials:  [default] aws_access_key_id / aws_secret_access_key  (a CURRENT, active key)
#   config:       [default] region = eu-west-1
aws configure                       # writes both files
aws sts get-caller-identity         # must print your Account + user ARN
```

The state bucket `prism-airflow-tf-state` (in `backend.tf`) must already exist.

## Initialise

```powershell
cd C:\RND\airflow-dag\terraform
terraform init
```

Connects to the S3 backend and pulls existing state. Re-run after changing
providers or backend config.

---

## Option 1 — sanity check against the real (CI-managed) state

Uses the shared `default` workspace. Shows that local execution works and sees
the infra CI already created. Does **not** change anything.

```powershell
terraform plan          # expect: "No changes. Your infrastructure matches the configuration."
```

Avoid `apply`/`destroy` here — that would act on the real `prism-dags` bucket.

---

## Option 2 — isolated create / verify / destroy in a separate workspace

A `localtest` workspace keeps its own state
(`s3://prism-airflow-tf-state/env:/localtest/...`), and `-var` points the config
at a throwaway bucket. The real `prism-dags` and CI state are untouched.

```powershell
# create the workspace (once)
terraform workspace new localtest

# create the test bucket
terraform apply -var="dags_bucket_name=prism-dags-localtest"

# verify
aws s3 ls | Select-String prism-dags
aws s3api get-bucket-versioning --bucket prism-dags-localtest

# (optional) mirror the DAG files in, like the pipeline's sync-dags job does
aws s3 sync ..\dags\ s3://prism-dags-localtest/dags/ --exclude "*" --include "*.py"
aws s3 ls s3://prism-dags-localtest/dags/

# tear down
aws s3 rm s3://prism-dags-localtest/dags/ --recursive          # empty it first (only if you synced)
terraform destroy -var="dags_bucket_name=prism-dags-localtest"

# leave the workspace clean
terraform workspace select default
terraform workspace delete localtest
```

### Workspace commands

```powershell
terraform workspace list        # * marks the active one
terraform workspace show
terraform workspace select default
```

---

## Notes

- **Terraform makes the bucket; `aws s3 sync` makes the `dags/` contents.** A
  fresh bucket has no `dags/` "folder" until files are synced into it.
- `-var="dags_bucket_name=..."` must be passed to **both** `apply` and
  `destroy` in Option 2 (Terraform needs the same inputs to plan the teardown).
- `terraform destroy` fails if the bucket still has objects (`force_destroy` is
  `false`) — empty it first.
- Region lives in two places that must agree: `var.aws_region` (`variables.tf`)
  and `region` in `backend.tf`. Both are `eu-west-1`.
