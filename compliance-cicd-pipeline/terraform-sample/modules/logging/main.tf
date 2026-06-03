# -----------------------------------------------------------------------------
# Module: Centralized Logging — S3 Log Bucket
# NIST 800-53: AU-9 (Protection of Audit Info), AU-11 (Audit Retention),
#              SC-28 (Protection at Rest)
# -----------------------------------------------------------------------------
# This bucket is the single destination for all audit logs in the org.
# CloudTrail, Config, and VPC Flow Logs all land here. It's locked down:
# encrypted, versioned, no public access, and only CloudTrail can write to it.
# -----------------------------------------------------------------------------

# --- Win 1: The Log Bucket ---
# SSE-S3 encryption (free, unlike KMS CMKs), versioning for tamper evidence.
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-audit-logs-${data.aws_caller_identity.current.account_id}"

  # Prevent accidental deletion of the audit log bucket
  force_destroy = false

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-audit-logs"
    Purpose    = "Centralized audit log storage"
    Compliance = "AU-9 / AU-11 / SC-28"
  })
}

# Need account ID for globally unique bucket naming
data "aws_caller_identity" "current" {}

# Enable versioning — tamper evidence for audit logs
# If someone modifies a log file, the original version is preserved.
# This is a FedRAMP requirement under AU-9.
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption — SSE-S3 (AES-256)
# Using AWS-managed keys to stay free tier. In production you'd use
# a KMS CMK ($1/mo), but SSE-S3 still satisfies SC-28.
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block ALL public access — defense in depth on top of the SCP
# Even if someone tries to change the bucket policy, this blocks it.
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Win 2: Bucket Policy — CloudTrail Access Only ---
# NIST 800-53: AU-9 (Protection of Audit Information)
# Only the CloudTrail service can write to this bucket.
# This prevents anyone from dumping random data into the audit logs
# or reading logs without proper IAM permissions.
resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  # Depend on public access block to avoid race condition
  depends_on = [aws_s3_bucket_public_access_block.logs]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
      },
      {
        Sid    = "AllowCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "DenyUnencryptedUploads"
        Effect = "Deny"
        Principal = "*"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = ["AES256", "aws:kms"]
          }
        }
      },
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = "*"
        Action   = "s3:*"
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# --- Win 3: Lifecycle Rules — Retention Policy ---
# NIST 800-53: AU-11 (Audit Record Retention)
# FedRAMP requires audit logs be retained for a defined period.
# - Move to Infrequent Access after 90 days (cheaper storage)
# - Move to Glacier after 365 days (archive tier)
# - Never auto-delete — compliance teams decide when to purge
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "audit-log-retention"
    status = "Enabled"

    # Apply to all objects in the bucket
    filter {}

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    # No expiration — audit logs are retained indefinitely
    # In production, set this based on your retention policy
    # (e.g., 7 years for FedRAMP High)
  }
}
