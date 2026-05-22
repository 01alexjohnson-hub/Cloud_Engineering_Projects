output "organization_id" {
  description = "The ID of the AWS Organization"
  value       = aws_organizations_organization.this.id
}

output "organization_arn" {
  description = "The ARN of the AWS Organization"
  value       = aws_organizations_organization.this.arn
}

output "security_ou_id" {
  description = "The ID of the Security OU"
  value       = aws_organizations_organizational_unit.security.id
}

output "workloads_ou_id" {
  description = "The ID of the Workloads OU"
  value       = aws_organizations_organizational_unit.workloads.id
}

output "scp_ids" {
  description = "Map of SCP names to their IDs"
  value = {
    deny_root       = aws_organizations_policy.deny_root_account.id
    restrict_regions = aws_organizations_policy.restrict_regions.id
    protect_audit   = aws_organizations_policy.protect_audit_logging.id
    enforce_s3      = aws_organizations_policy.enforce_s3_security.id
    deny_leave_org  = aws_organizations_policy.deny_leave_org.id
  }
}
