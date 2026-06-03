# -----------------------------------------------------------------------------
# Security Hub Module Outputs
# -----------------------------------------------------------------------------

output "hub_arn" {
  description = "ARN of the Security Hub account"
  value       = aws_securityhub_account.this.arn
}

output "nist_subscription_arn" {
  description = "ARN of the NIST 800-53 standards subscription"
  value       = aws_securityhub_standards_subscription.nist_800_53.id
}
