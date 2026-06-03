# -----------------------------------------------------------------------------
# Module: Security Hub — Compliance Dashboard & Findings Aggregation
# NIST 800-53: CA-7 (Continuous Monitoring), RA-5 (Vulnerability Scanning)
# -----------------------------------------------------------------------------
# Security Hub is the central nervous system for security findings. It:
# - Aggregates findings from GuardDuty, Config, Inspector, etc.
# - Scores your environment against compliance standards (NIST 800-53!)
# - Gives you a single dashboard showing your security posture
#
# For FedRAMP, this is your CA-7 implementation. When an assessor asks
# "how do you do continuous monitoring?", Security Hub is the answer.
# -----------------------------------------------------------------------------

# --- Win 3: Enable Security Hub ---
resource "aws_securityhub_account" "this" {
  auto_enable_controls = true

  # Control finding generator — Security Hub generates its own findings
  # per control, not just aggregating from other services
  control_finding_generator = "SECURITY_CONTROL"
}

# --- Subscribe to NIST 800-53 Rev 5 Standard ---
# This is the money shot for the portfolio. Security Hub will automatically
# evaluate your environment against NIST 800-53 controls and give you a
# compliance score. Recruiters/interviewers can see you didn't just
# name-drop controls — you have automated checks running.
resource "aws_securityhub_standards_subscription" "nist_800_53" {
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/nist-800-53/v/5.0.0"

  depends_on = [aws_securityhub_account.this]
}

# Also enable AWS Foundational Security Best Practices — this catches
# things NIST doesn't explicitly cover (like specific AWS misconfigs)
resource "aws_securityhub_standards_subscription" "aws_foundational" {
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"

  depends_on = [aws_securityhub_account.this]
}

# Need region for standards ARN construction
data "aws_region" "current" {}
