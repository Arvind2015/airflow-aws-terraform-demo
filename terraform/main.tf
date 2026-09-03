# ---------------------------------------------------------------------------
# S3 bucket that holds the Airflow DAG files.
# The GitHub Actions workflow runs `aws s3 sync dags/ s3://<bucket>/dags/`
# on every merge to main.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "dags" {
  bucket = var.dags_bucket_name
}

resource "aws_s3_bucket_versioning" "dags" {
  bucket = aws_s3_bucket.dags.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "dags" {
  bucket = aws_s3_bucket.dags.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dags" {
  bucket = aws_s3_bucket.dags.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
