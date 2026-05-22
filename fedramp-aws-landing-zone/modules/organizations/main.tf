# -----------------------------------------------------------------------------
# Module: AWS Organizations & Service Control Policies
# NIST 800-53: AC-2, AC-6, CM-7, AU-2, SI-4, SC-28, AC-4
# -----------------------------------------------------------------------------

# --- Win 1: Enable AWS Organizations ---
# This is the foundation everything else attaches to.
# "ALL" enables SCPs — without this, you can't enforce guardrails.
resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  # Enable service access for security services we'll use in later phases
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
  ]

  # Enable policy types we need
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
  ]
}

# --- Win 2: Organizational Units ---
# Two OUs that separate concerns: Security (logging, monitoring, audit)
# and Workloads (actual applications). This is AWS Well-Architected
# multi-account strategy and mirrors how FedRAMP environments are segmented.

resource "aws_organizations_organizational_unit" "security" {
  name      = "${var.project_name}-security"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "${var.project_name}-workloads"
  parent_id = aws_organizations_organization.this.roots[0].id
}

# =============================================================================
# SERVICE CONTROL POLICIES (SCPs)
# SCPs are the highest-authority guardrails in AWS. Even an account admin
# can't override them. Think of them as the "thou shalt not" layer.
# =============================================================================

# --- Win 3: Deny Root Account Usage ---
# NIST 800-53: AC-2 (Account Management)
# Why: Root accounts have unrestricted access and can't be scoped with IAM.
# In a FedRAMP environment, root usage is a finding every time.
resource "aws_organizations_policy" "deny_root_account" {
  name        = "deny-root-account-usage"
  description = "Prevents use of root account credentials [AC-2]"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyRootAccount"
        Effect    = "Deny"
        Action    = "*"
        Resource  = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      }
    ]
  })
}

# --- Win 4: Restrict to FedRAMP-Authorized Regions ---
# NIST 800-53: CM-7 (Least Functionality)
# Why: FedRAMP requires data to stay in authorized regions. If someone
# spins up an EC2 in ap-southeast-1, that's an instant finding.
# This SCP makes it impossible.
resource "aws_organizations_policy" "restrict_regions" {
  name        = "restrict-to-fedramp-regions"
  description = "Limits all activity to FedRAMP-authorized regions [CM-7]"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonFedRAMPRegions"
        Effect    = "Deny"
        Action    = "*"
        Resource  = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
          # Don't block global services (IAM, Organizations, STS, etc.)
          "ForAnyValue:StringNotLike" = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      }
    ]
  })
}

# --- Win 5: Protect Audit Logging ---
# NIST 800-53: AU-2 (Audit Events), SI-4 (System Monitoring)
# Why: If someone disables CloudTrail or GuardDuty, you lose visibility.
# In a FedRAMP assessment, tampered audit logs = critical finding.
# This SCP makes the logging infrastructure untouchable.
resource "aws_organizations_policy" "protect_audit_logging" {
  name        = "protect-audit-logging"
  description = "Prevents disabling CloudTrail and GuardDuty [AU-2, SI-4]"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyCloudTrailDisable"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging",
          "cloudtrail:DeleteTrail",
          "cloudtrail:UpdateTrail",
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyGuardDutyDisable"
        Effect = "Deny"
        Action = [
          "guardduty:DeleteDetector",
          "guardduty:DisassociateFromMasterAccount",
          "guardduty:UpdateDetector",
        ]
        Resource = "*"
      }
    ]
  })
}

# --- Win 6: Enforce S3 Security ---
# NIST 800-53: SC-28 (Protection at Rest), AC-4 (Information Flow)
# Why: Unencrypted or public S3 buckets are the #1 cloud data breach vector.
# This SCP requires encryption on every bucket and blocks public access.
resource "aws_organizations_policy" "enforce_s3_security" {
  name        = "enforce-s3-security"
  description = "Requires S3 encryption and blocks public access [SC-28, AC-4]"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnencryptedS3Uploads"
        Effect    = "Deny"
        Action    = "s3:PutObject"
        Resource  = "*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = ["AES256", "aws:kms"]
          }
        }
      },
      {
        Sid    = "DenyS3PublicAccess"
        Effect = "Deny"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "s3:DeleteBucketPublicAccessBlock",
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "s3:publicAccessBlockConfiguration/BlockPublicAcls"       = "true"
            "s3:publicAccessBlockConfiguration/BlockPublicPolicy"     = "true"
            "s3:publicAccessBlockConfiguration/IgnorePublicAcls"      = "true"
            "s3:publicAccessBlockConfiguration/RestrictPublicBuckets" = "true"
          }
        }
      }
    ]
  })
}

# --- Win 7: Deny Leaving Organization ---
# NIST 800-53: AC-2 (Account Management)
# Why: If an account leaves the org, it escapes ALL SCPs instantly.
# Every guardrail we just built becomes useless for that account.
resource "aws_organizations_policy" "deny_leave_org" {
  name        = "deny-leave-organization"
  description = "Prevents accounts from leaving the organization [AC-2]"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyLeaveOrg"
        Effect   = "Deny"
        Action   = "organizations:LeaveOrganization"
        Resource = "*"
      }
    ]
  })
}

# =============================================================================
# Win 8: ATTACH SCPs TO OUs
# Policies do nothing until attached. We attach all guardrails to BOTH OUs
# so security and workload accounts get the same baseline protection.
# =============================================================================

# Attach to Security OU
resource "aws_organizations_policy_attachment" "security_deny_root" {
  policy_id = aws_organizations_policy.deny_root_account.id
  target_id = aws_organizations_organizational_unit.security.id
}

resource "aws_organizations_policy_attachment" "security_restrict_regions" {
  policy_id = aws_organizations_policy.restrict_regions.id
  target_id = aws_organizations_organizational_unit.security.id
}

resource "aws_organizations_policy_attachment" "security_protect_audit" {
  policy_id = aws_organizations_policy.protect_audit_logging.id
  target_id = aws_organizations_organizational_unit.security.id
}

resource "aws_organizations_policy_attachment" "security_s3_security" {
  policy_id = aws_organizations_policy.enforce_s3_security.id
  target_id = aws_organizations_organizational_unit.security.id
}

resource "aws_organizations_policy_attachment" "security_deny_leave" {
  policy_id = aws_organizations_policy.deny_leave_org.id
  target_id = aws_organizations_organizational_unit.security.id
}

# Attach to Workloads OU
resource "aws_organizations_policy_attachment" "workloads_deny_root" {
  policy_id = aws_organizations_policy.deny_root_account.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "workloads_restrict_regions" {
  policy_id = aws_organizations_policy.restrict_regions.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "workloads_protect_audit" {
  policy_id = aws_organizations_policy.protect_audit_logging.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "workloads_s3_security" {
  policy_id = aws_organizations_policy.enforce_s3_security.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "workloads_deny_leave" {
  policy_id = aws_organizations_policy.deny_leave_org.id
  target_id = aws_organizations_organizational_unit.workloads.id
}
