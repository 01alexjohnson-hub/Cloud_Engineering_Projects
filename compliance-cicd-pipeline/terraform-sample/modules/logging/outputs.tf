# -----------------------------------------------------------------------------
# Logging Module Outputs
# -----------------------------------------------------------------------------

output "log_bucket_arn" {
  description = "ARN of the centralized audit log bucket"
  value       = aws_s3_bucket.logs.arn
}

output "log_bucket_id" {
  description = "ID (name) of the centralized audit log bucket"
  value       = aws_s3_bucket.logs.id
}

output "log_bucket_name" {
  description = "Name of the centralized audit log bucket"
  value       = aws_s3_bucket.logs.bucket
}
