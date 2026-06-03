# DEMO: Intentionally non-compliant infrastructure
# This file should be BLOCKED by the compliance pipeline

# Violation 1: S3 bucket with no encryption (SC-28)
# Violation 2: S3 bucket with no public access block (AC-3)
resource "aws_s3_bucket" "bad_bucket" {
  bucket = "demo-non-compliant-bucket"
}

# Violation 3: IAM policy with wildcard actions (AC-6)
resource "aws_iam_policy" "bad_policy" {
  name   = "overly-permissive-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}

# Violation 4: Missing required tags (CM-8)
resource "aws_s3_bucket" "untagged_bucket" {
  bucket        = "demo-untagged-bucket"
  force_destroy = true

  tags = {
    Name = "untagged-bucket"
  }
}
