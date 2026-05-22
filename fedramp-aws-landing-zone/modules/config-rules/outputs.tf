# -----------------------------------------------------------------------------
# Config Rules Module Outputs
# -----------------------------------------------------------------------------

output "recorder_id" {
  description = "ID of the AWS Config recorder"
  value       = aws_config_configuration_recorder.this.id
}

output "config_rule_arns" {
  description = "Map of Config Rule names to their ARNs"
  value = {
    s3_encryption  = aws_config_config_rule.s3_encryption.arn
    ebs_encryption = aws_config_config_rule.ebs_encryption.arn
    rds_encryption = aws_config_config_rule.rds_encryption.arn
    iam_mfa        = aws_config_config_rule.iam_mfa.arn
    restricted_ssh = aws_config_config_rule.restricted_ssh.arn
    root_mfa       = aws_config_config_rule.root_mfa.arn
  }
}
