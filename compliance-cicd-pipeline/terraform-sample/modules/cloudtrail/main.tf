# -----------------------------------------------------------------------------
# Module: CloudTrail — Organization-Wide Audit Trail
# NIST 800-53: AU-2 (Audit Events), AU-3 (Content of Audit Records),
#              AU-6 (Audit Review, Analysis, and Reporting)
# -----------------------------------------------------------------------------
# CloudTrail is the audit log for your entire AWS environment. Every API call
# — who did what, when, from where — gets recorded. For FedRAMP, this is
# non-negotiable. An org-wide trail means every account is covered
# automatically, even new ones added later.
# -----------------------------------------------------------------------------

# --- Win 5: CloudWatch Log Group ---
# NIST 800-53: AU-6 (Audit Review)
# CloudTrail writes to S3 for long-term storage, but CloudWatch gives you
# real-time search and alerting. You can't investigate an incident by
# downloading S3 objects — you need CloudWatch for that.
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 90

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-cloudtrail-logs"
    Compliance = "AU-6"
  })
}

# IAM role that allows CloudTrail to deliver logs to CloudWatch
# CloudTrail needs explicit permission to write to your log group.
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-cloudtrail-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudTrailAssume"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-cloudtrail-cloudwatch-role"
    Purpose = "Allow CloudTrail to deliver logs to CloudWatch"
  })
}

# Policy that grants CloudTrail permission to create log streams and put events
resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-cloudtrail-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# --- Win 6: Organization-Wide CloudTrail ---
# NIST 800-53: AU-2 (Audit Events), AU-3 (Content of Audit Records)
# This is THE audit trail. One trail covers the entire org:
# - is_organization_trail = true → every account, automatic
# - is_multi_region_trail = true → every region, no blind spots
# - Management events = all API calls (create, delete, modify)
# - enable_log_file_validation = true → tamper detection via digest files
resource "aws_cloudtrail" "org_trail" {
  name = "${var.project_name}-org-trail"

  # S3 destination — the centralized log bucket from the logging module
  s3_bucket_name = var.log_bucket_name

  # CloudWatch destination — for real-time search and alerting
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch.arn

  # Organization-wide: covers all accounts, including future ones
  is_organization_trail = true

  # Multi-region: no blind spots even if someone tries to act in another region
  is_multi_region_trail = true

  # Log file validation: CloudTrail creates digest files that let you verify
  # no log files were modified or deleted after delivery. This is the
  # tamper-evidence mechanism auditors look for.
  enable_log_file_validation = true

  # Include global service events (IAM, STS, CloudFront)
  include_global_service_events = true

  # Management events: capture all read/write API calls
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-org-trail"
    Compliance = "AU-2 / AU-3"
  })

  # Ensure the bucket policy is in place before creating the trail
  depends_on = [var.log_bucket_policy_dependency]
}
