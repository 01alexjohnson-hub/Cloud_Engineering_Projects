# -----------------------------------------------------------------------------
# IAM Module Outputs
# -----------------------------------------------------------------------------

output "permission_boundary_arn" {
  description = "ARN of the permission boundary policy"
  value       = aws_iam_policy.permission_boundary.arn
}

output "admin_role_arn" {
  description = "ARN of the admin role (bounded)"
  value       = aws_iam_role.admin.arn
}

output "admin_role_name" {
  description = "Name of the admin role"
  value       = aws_iam_role.admin.name
}

output "readonly_role_arn" {
  description = "ARN of the read-only auditor role"
  value       = aws_iam_role.readonly.arn
}

output "readonly_role_name" {
  description = "Name of the read-only auditor role"
  value       = aws_iam_role.readonly.name
}
