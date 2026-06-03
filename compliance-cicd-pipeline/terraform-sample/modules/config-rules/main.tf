# -----------------------------------------------------------------------------
# Module: AWS Config Rules — Configuration Compliance
# NIST 800-53: CA-7 (Continuous Monitoring), CM-6 (Configuration Settings),
#              SC-28 (Protection at Rest), IA-2 (Identification & Auth),
#              AC-4 (Information Flow Enforcement)
# -----------------------------------------------------------------------------
# AWS Config continuously records your resource configurations and evaluates
# them against rules. Think of it as automated compliance checking:
# "Is every S3 bucket encrypted? Is every security group locked down?"
#
# Config Rules are the backbone of CM-6 (Configuration Settings) — they
# prove that your baseline configurations are enforced continuously,
# not just at deploy time.
# -----------------------------------------------------------------------------

# --- Win 5: AWS Config Recorder + IAM Role ---
# The recorder watches your resources. The IAM role gives Config
# permission to read resource configurations and write to S3.

# IAM role that AWS Config assumes to read resource configurations
resource "aws_iam_role" "config" {
  name = "${var.project_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowConfigAssume"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-config-role"
    Purpose = "Allow AWS Config to record resource configurations"
  })
}

# Attach the AWS managed policy for Config
# This gives Config read access to all resource types
resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Policy for Config to deliver to S3
resource "aws_iam_role_policy" "config_s3_delivery" {
  name = "${var.project_name}-config-s3-delivery"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3PutConfig"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl",
        ]
        Resource = [
          var.log_bucket_arn,
          "${var.log_bucket_arn}/*",
        ]
      }
    ]
  })
}

# The Config recorder — records all supported resource types
resource "aws_config_configuration_recorder" "this" {
  name     = "${var.project_name}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# --- Win 6: Delivery Channel ---
# Config snapshots and history go to the centralized log bucket.
# This keeps all audit data in one place — S3 bucket from Phase 3.
resource "aws_config_delivery_channel" "this" {
  name           = "${var.project_name}-delivery"
  s3_bucket_name = var.log_bucket_name

  # Deliver config snapshots every 6 hours
  snapshot_delivery_properties {
    delivery_frequency = "Six_Hours"
  }

  depends_on = [aws_config_configuration_recorder.this]
}

# Enable the recorder — it won't start recording until explicitly enabled
resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

# =============================================================================
# CONFIG RULES — AWS Managed Rules
# These are pre-built rules maintained by AWS. We're using managed rules
# (not custom) because they're free for the first 25 evaluations/region
# and they map directly to NIST 800-53 controls.
# =============================================================================

# --- Win 7: Encryption Rules ---
# NIST 800-53: SC-28 (Protection of Information at Rest)

# S3 buckets must have server-side encryption enabled
resource "aws_config_config_rule" "s3_encryption" {
  name = "${var.project_name}-s3-bucket-encryption"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  tags = merge(var.common_tags, {
    Compliance = "SC-28"
  })

  depends_on = [aws_config_configuration_recorder.this]
}

# EBS volumes must be encrypted
resource "aws_config_config_rule" "ebs_encryption" {
  name = "${var.project_name}-ebs-encryption"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  tags = merge(var.common_tags, {
    Compliance = "SC-28"
  })

  depends_on = [aws_config_configuration_recorder.this]
}

# RDS instances must be encrypted
resource "aws_config_config_rule" "rds_encryption" {
  name = "${var.project_name}-rds-encryption"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  tags = merge(var.common_tags, {
    Compliance = "SC-28"
  })

  depends_on = [aws_config_configuration_recorder.this]
}

# --- Win 8: Access Control Rules ---

# IAM users must have MFA enabled
# NIST 800-53: IA-2 (Identification and Authentication)
# MFA is a baseline requirement for FedRAMP. Any IAM user without
# MFA is an automatic finding.
resource "aws_config_config_rule" "iam_mfa" {
  name = "${var.project_name}-iam-user-mfa"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_MFA_ENABLED"
  }

  tags = merge(var.common_tags, {
    Compliance = "IA-2"
  })

  depends_on = [aws_config_configuration_recorder.this]
}

# Security groups must not allow unrestricted SSH (0.0.0.0/0 on port 22)
# NIST 800-53: AC-4 (Information Flow Enforcement)
# Open SSH to the world is the cloud equivalent of leaving your
# front door open. This catches it automatically.
resource "aws_config_config_rule" "restricted_ssh" {
  name = "${var.project_name}-restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  tags = merge(var.common_tags, {
    Compliance = "AC-4"
  })

  depends_on = [aws_config_configuration_recorder.this]
}

# Root account must have MFA enabled
# NIST 800-53: IA-2 (Identification and Authentication)
# Even though our SCP denies root usage, belt + suspenders.
# Assessors check for this explicitly.
resource "aws_config_config_rule" "root_mfa" {
  name = "${var.project_name}-root-account-mfa"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  tags = merge(var.common_tags, {
    Compliance = "IA-2"
  })

  depends_on = [aws_config_configuration_recorder.this]
}
