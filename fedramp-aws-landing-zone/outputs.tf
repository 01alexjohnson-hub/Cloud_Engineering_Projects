# -----------------------------------------------------------------------------
# Root Module Outputs
# These will be populated as modules are enabled in each phase
# -----------------------------------------------------------------------------

# Phase 2 outputs ✓
output "organization_id" {
  description = "AWS Organization ID"
  value       = module.organizations.organization_id
}

output "security_ou_id" {
  description = "Security OU ID"
  value       = module.organizations.security_ou_id
}

output "workloads_ou_id" {
  description = "Workloads OU ID"
  value       = module.organizations.workloads_ou_id
}

# Phase 3 outputs ✓
output "cloudtrail_arn" {
  description = "ARN of the organization-wide CloudTrail"
  value       = module.cloudtrail.trail_arn
}

output "log_bucket_arn" {
  description = "ARN of the centralized logging S3 bucket"
  value       = module.logging.log_bucket_arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group for CloudTrail logs"
  value       = module.cloudtrail.cloudwatch_log_group_name
}

# Phase 4 outputs ✓
output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = module.guardduty.detector_id
}

output "security_hub_arn" {
  description = "Security Hub ARN"
  value       = module.security_hub.hub_arn
}

output "config_rule_arns" {
  description = "Map of Config Rule names to ARNs"
  value       = module.config_rules.config_rule_arns
}

# Phase 5 outputs ✓
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "admin_role_arn" {
  description = "ARN of the bounded admin role"
  value       = module.iam.admin_role_arn
}

output "readonly_role_arn" {
  description = "ARN of the read-only auditor role"
  value       = module.iam.readonly_role_arn
}

output "permission_boundary_arn" {
  description = "ARN of the permission boundary policy"
  value       = module.iam.permission_boundary_arn
}
