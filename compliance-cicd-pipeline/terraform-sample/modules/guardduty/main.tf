# -----------------------------------------------------------------------------
# Module: GuardDuty — Threat Detection
# NIST 800-53: SI-4 (System Monitoring), RA-5 (Vulnerability Scanning)
# -----------------------------------------------------------------------------
# GuardDuty is AWS's managed threat detection service. It analyzes:
# - CloudTrail logs (account compromise, unusual API calls)
# - VPC Flow Logs (port scanning, C2 communication)
# - DNS logs (crypto mining, data exfiltration)
#
# For FedRAMP, GuardDuty is the primary SI-4 implementation. Without it,
# you're telling the assessor "we have no automated threat detection."
# That's a critical finding every time.
# -----------------------------------------------------------------------------

# --- Win 1: GuardDuty Detector ---
# The detector is the top-level resource. Enabling it starts analyzing
# CloudTrail, VPC Flow Logs, and DNS logs automatically.
resource "aws_guardduty_detector" "this" {
  enable = true

  # Optional data sources — these are included in the 30-day free trial
  datasources {
    s3_logs {
      enable = true
    }
  }

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-guardduty"
    Compliance = "SI-4 / RA-5"
  })
}
