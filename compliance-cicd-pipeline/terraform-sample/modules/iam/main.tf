# -----------------------------------------------------------------------------
# Module: IAM Baseline — Roles & Permission Boundaries
# NIST 800-53: AC-6 (Least Privilege), IA-2 (Identification & Auth),
#              AC-2 (Account Management), AC-17 (Remote Access)
# -----------------------------------------------------------------------------
# This module implements the IAM layer of the landing zone:
# - Permission boundaries cap the maximum permissions ANY role can have
# - Admin role has full access BUT bounded by the permission boundary
# - ReadOnly role for auditors/assessors (they only need to look, not touch)
# - No long-lived access keys — roles only, assumed via federation/SSO
#
# For FedRAMP, AC-6 (Least Privilege) is one of the most scrutinized controls.
# Permission boundaries are what you show the assessor to prove that even
# admins can't exceed the defined ceiling.
# -----------------------------------------------------------------------------

# Need account ID for ARN construction
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# Win 8: PERMISSION BOUNDARY — The Ceiling on All Permissions
# NIST 800-53: AC-6 (Least Privilege)
# A permission boundary is an IAM policy that defines the MAXIMUM permissions
# a role can have. Even if someone attaches AdministratorAccess to a role,
# the boundary clips it. This is the safety net for privilege escalation.
# =============================================================================

resource "aws_iam_policy" "permission_boundary" {
  name        = "${var.project_name}-permission-boundary"
  description = "Permission boundary - caps maximum allowed permissions [AC-6]"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowedServices"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "rds:*",
          "lambda:*",
          "logs:*",
          "cloudwatch:*",
          "ssm:*",
          "kms:*",
          "sns:*",
          "sqs:*",
          "iam:Get*",
          "iam:List*",
          "iam:PassRole",
          "sts:AssumeRole",
          "sts:GetCallerIdentity",
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyBoundaryModification"
        Effect = "Deny"
        Action = [
          "iam:DeletePolicy",
          "iam:DeletePolicyVersion",
          "iam:CreatePolicyVersion",
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-permission-boundary"
      },
      {
        Sid      = "DenyLeavingOrg"
        Effect   = "Deny"
        Action   = "organizations:LeaveOrganization"
        Resource = "*"
      },
      {
        # Restrict to FedRAMP regions — even through IAM
        Sid    = "DenyNonFedRAMPRegions"
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
          # Don't block global services
          "ForAnyValue:StringNotLike" = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-permission-boundary"
    Compliance = "AC-6"
  })
}

# =============================================================================
# Win 9: ADMIN ROLE — Full Access, Bounded
# NIST 800-53: AC-6 (Least Privilege), IA-2 (Identification & Auth)
# This role has AdministratorAccess BUT the permission boundary caps it.
# The boundary prevents: modifying itself, leaving the org, acting
# outside FedRAMP regions. This is how you prove to an assessor that
# even admin access is controlled.
# =============================================================================

resource "aws_iam_role" "admin" {
  name = "${var.project_name}-admin-role"

  # Only principals in this account can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountAssume"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })

  # THE KEY LINE — this is what makes this FedRAMP-ready
  permissions_boundary = aws_iam_policy.permission_boundary.arn

  max_session_duration = 3600 # 1 hour max — forces re-auth

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-admin-role"
    Compliance = "AC-6 / IA-2"
  })
}

# Attach AdministratorAccess — but remember, it's clipped by the boundary
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# =============================================================================
# Win 10: READONLY ROLE — Auditor/Assessor Access
# NIST 800-53: AC-6 (Least Privilege), AC-2 (Account Management)
# Auditors need to see everything but change nothing. This role gives
# read-only access to all services. In a FedRAMP assessment, the 3PAO
# team uses a role exactly like this to review your environment.
# =============================================================================

resource "aws_iam_role" "readonly" {
  name = "${var.project_name}-readonly-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountAssume"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })

  # Still bounded — even read-only can't escape the region restriction
  permissions_boundary = aws_iam_policy.permission_boundary.arn

  max_session_duration = 3600

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-readonly-role"
    Compliance = "AC-6 / AC-2"
    Purpose    = "3PAO assessor and auditor access"
  })
}

# ReadOnlyAccess — AWS managed policy covering all services
resource "aws_iam_role_policy_attachment" "readonly" {
  role       = aws_iam_role.readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Also attach SecurityAudit for deeper security-specific visibility
resource "aws_iam_role_policy_attachment" "readonly_security_audit" {
  role       = aws_iam_role.readonly.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}
