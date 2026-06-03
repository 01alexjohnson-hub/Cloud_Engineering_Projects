# Changelog

## v1.0.0 — 2026-06-03

Initial release of the Compliance-as-Code CI/CD Pipeline.

### Pipeline

- 7-stage GitHub Actions workflow: tflint → terraform validate → Checkov → terraform plan → OPA eval → compliance report → PR comment
- Baseline-aware gate that fails on new violations while accepting documented free-tier gaps
- Automated compliance report posted as a sticky PR comment
- All scan results uploaded as downloadable artifacts (Checkov JSON, OPA results, compliance report)

### OPA Policies (7 controls)

- `s3_encryption.rego` — SC-28: S3 server-side encryption required
- `s3_public_access.rego` — AC-3: S3 public access must be blocked
- `iam_no_wildcards.rego` — AC-6: IAM policies must not use wildcard actions
- `cloudtrail_encryption.rego` — AU-9: CloudTrail must use KMS encryption
- `vpc_restricted_ingress.rego` — SC-7: No unrestricted ingress on sensitive ports (22, 3389, 3306, 5432, 1433, 27017)
- `logging_enabled.rego` — AU-2: CloudTrail logging must be enabled
- `tags_required.rego` — CM-8: Resources must have Environment, ManagedBy, Project, and Compliance tags

### Checkov Configuration

- Scoped to 17 checks across 4 NIST 800-53 control families (SC, AC, AU, CM)
- Custom `.checkov.yaml` eliminates noise from irrelevant checks

### Compliance Report

- Python script (`scripts/generate_report.py`) parses Checkov JSON and OPA results
- Outputs combined markdown report with summary table, OPA findings with control IDs, and Checkov failure details

### Security

- Dedicated read-only IAM user for CI (`github-actions-ci`) with 12 services, no write access
- AWS credentials stored as GitHub Secrets, masked in logs
- Node.js 24 opted in to avoid deprecation warnings

### Demo

- PR #1: Non-compliant infrastructure blocked (5 new Checkov violations, pipeline failed)
- PR #2: Compliant infrastructure passed all gates (62.5% baseline pass rate, no new violations)
- Screenshots saved to `docs/screenshots/`

### Documentation

- README with architecture diagram, policy mapping, quick start, and baseline scan results
- POLICY_MAPPING.md mapping each OPA policy to its NIST 800-53 control
- Production improvements section covering OIDC, branch protection, expanded policies
