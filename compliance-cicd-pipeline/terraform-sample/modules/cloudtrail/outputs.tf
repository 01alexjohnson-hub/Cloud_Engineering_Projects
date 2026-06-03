# -----------------------------------------------------------------------------
# CloudTrail Module Outputs
# -----------------------------------------------------------------------------

output "trail_arn" {
  description = "ARN of the organization-wide CloudTrail"
  value       = aws_cloudtrail.org_trail.arn
}

output "trail_name" {
  description = "Name of the organization-wide CloudTrail"
  value       = aws_cloudtrail.org_trail.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for CloudTrail"
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for CloudTrail"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}
