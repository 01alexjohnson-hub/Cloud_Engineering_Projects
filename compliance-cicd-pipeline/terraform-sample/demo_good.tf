# DEMO: Fully compliant infrastructure
# This file should PASS all compliance pipeline checks

# Compliant S3 bucket with encryption, public access block, and tags
resource "aws_s3_bucket" "compliant_bucket" {
  bucket = "demo-compliant-bucket"

  tags = {
    Name        = "demo-compliant-bucket"
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "fedramp-landing-zone"
    Compliance  = "SC-28"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "compliant_bucket" {
  bucket = aws_s3_bucket.compliant_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "compliant_bucket" {
  bucket = aws_s3_bucket.compliant_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
