# -----------------------------------------------------------------------------
# VPC Module Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  description = "Security group ID for the ALB tier"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group ID for the App tier"
  value       = aws_security_group.app.id
}

output "data_security_group_id" {
  description = "Security group ID for the Data tier"
  value       = aws_security_group.data.id
}

output "flow_log_group_name" {
  description = "CloudWatch log group for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.flow_logs.name
}
