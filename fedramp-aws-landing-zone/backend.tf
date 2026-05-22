# -----------------------------------------------------------------------------
# Remote State Configuration
# S3 bucket + DynamoDB table for state locking
# -----------------------------------------------------------------------------
# IMPORTANT: The S3 bucket and DynamoDB table must exist BEFORE running
# terraform init. Use the bootstrap script at scripts/bootstrap-state.sh
# to create them, or create manually in the AWS console.
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "fedramp-landing-zone-tfstate"
    key            = "landing-zone/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}
