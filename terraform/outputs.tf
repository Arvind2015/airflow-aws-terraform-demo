output "dags_bucket_name" {
  description = "Name of the S3 bucket holding DAG files"
  value       = aws_s3_bucket.dags.id
}

output "dags_s3_uri" {
  description = "S3 URI the DAG sync step writes to"
  value       = "s3://${aws_s3_bucket.dags.id}/${var.dags_prefix}/"
}
