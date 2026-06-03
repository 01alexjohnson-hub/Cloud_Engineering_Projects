# -----------------------------------------------------------------------------
# FedRAMP-Ready AWS Landing Zone
# Root Module
# -----------------------------------------------------------------------------
# This is the root module that orchestrates all child modules.
# Each module maps to a set of NIST 800-53 controls documented in
# CONTROL_MAPPING.md.
#
# Build order:
#   Phase 2: Organizations & SCPs
#   Phase 3: Centralized Logging (CloudTrail + S3)
#   Phase 4: Threat Detection (GuardDuty, Security Hub, Config Rules)
#   Phase 5: Network & IAM Baseline
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

# -----------------------------------------------------------------------------
# Phase 2: AWS Organizations & SCPs ✓ COMPLETE
# Controls: AC-2, AC-6, CM-7, AU-2, SI-4, SC-28, AC-4
# -----------------------------------------------------------------------------
module "organizations" {
  source = "./modules/organizations"

  project_name    = var.project_name
  environment     = var.environment
  allowed_regions = ["us-east-1", "us-east-2", "us-west-2"]
}

# -----------------------------------------------------------------------------
# Phase 3: Centralized Logging & Audit ✓ COMPLETE
# Controls: AU-2, AU-3, AU-6, AU-9, AU-11, SC-28
# -----------------------------------------------------------------------------
module "logging" {
  source = "./modules/logging"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags
}

module "cloudtrail" {
  source = "./modules/cloudtrail"

  project_name                 = var.project_name
  log_bucket_name              = module.logging.log_bucket_name
  log_bucket_policy_dependency = module.logging.log_bucket_arn
  common_tags                  = var.common_tags
}

# -----------------------------------------------------------------------------
# Phase 4: Threat Detection & Compliance Monitoring ✓ COMPLETE
# Controls: SI-4, CA-7, RA-5, CM-6, IA-2, AC-4, SC-28
# -----------------------------------------------------------------------------
module "guardduty" {
  source = "./modules/guardduty"

  project_name = var.project_name
  common_tags  = var.common_tags
}

module "security_hub" {
  source = "./modules/security-hub"

  project_name = var.project_name
  common_tags  = var.common_tags
}

module "config_rules" {
  source = "./modules/config-rules"

  project_name    = var.project_name
  log_bucket_name = module.logging.log_bucket_name
  log_bucket_arn  = module.logging.log_bucket_arn
  common_tags     = var.common_tags
}

# -----------------------------------------------------------------------------
# Phase 5: Network & IAM Baseline ✓ COMPLETE
# Controls: SC-7, AC-4, AC-6, IA-2, AC-17, SI-4, AU-2
# -----------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  common_tags        = var.common_tags
}

module "iam" {
  source = "./modules/iam"

  project_name    = var.project_name
  environment     = var.environment
  allowed_regions = ["us-east-1", "us-east-2", "us-west-2"]
  common_tags     = var.common_tags
}
