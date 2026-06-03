# Compliance-as-Code CI/CD Pipeline

GitHub Actions pipeline that scans Terraform against custom NIST 800-53 policy sets and blocks non-compliant deployments before they reach an environment.

**7 OPA policies | 17 Checkov checks | 7 pipeline stages | 7 NIST 800-53 controls | $0 cost**

### Built With

`GitHub Actions` `Open Policy Agent` `Rego` `Checkov` `Terraform` `tflint` `Python` `AWS IAM` `NIST 800-53`

---

## What This Proves

Most compliance violations in production trace back to the same root cause: somebody deployed something that never should have passed a policy check. This project is the policy check.

It combines off-the-shelf static analysis (Checkov, 800+ built-in rules) with custom policy-as-code (OPA/Rego, mapped to specific NIST 800-53 controls) in a single automated pipeline. Every PR gets scanned. Non-compliant infrastructure gets blocked. The compliance report posts directly on the PR so reviewers see the findings without digging through logs.

Built by a cloud engineer with FedRAMP 3PAO assessment experience (Coalfire). The policies come from years of seeing the same findings on real assessments — these are the checks that would have caught the issues before they became findings.

## Key Design Decisions

**Two-layer scanning, not one** — Checkov catches the broad set (encryption, public access, IAM hygiene) with zero configuration. OPA handles the organization-specific rules that off-the-shelf tools don't cover. Together they provide defense in depth at the CI layer.

**Policies mapped to controls, not just best practices** — Every OPA policy cites the specific NIST 800-53 control it enforces. When the pipeline blocks a deployment, the denial message includes the control ID. An assessor can trace from a blocked PR directly to the requirement it violated.

**Baseline-aware gating** — The pipeline distinguishes between known baseline findings (free-tier constraints documented in the compliance report) and new violations introduced by a PR. Clean code passes even when the baseline has accepted gaps. New violations fail the gate.

**Least-privilege CI credentials** — The pipeline's AWS access uses a dedicated IAM user with read-only permissions (12 services, no write access). The CI/CD system itself demonstrates AC-6.

## Pipeline Demo

Non-compliant infrastructure submitted as a PR — pipeline catches 5 violations and blocks the merge:

![Failed PR](./docs/screenshots/pr-failed-overview.png)

Compliant infrastructure passes all policy gates:

![Passed PR](./docs/screenshots/pr-passed-checks.png)

---

## Pipeline Architecture

```
Pull Request Opened
        │
        ▼
┌───────────────┐
│  Stage 1      │
│  tflint       │──── Terraform linting (syntax, deprecations)
└───────┬───────┘
        ▼
┌───────────────┐
│  Stage 2      │
│  tf validate  │──── Configuration validation
└───────┬───────┘
        ▼
┌───────────────┐
│  Stage 3      │
│  Checkov      │──── Static analysis (17 scoped checks)
└───────┬───────┘     Output: checkov-results.json
        ▼
┌───────────────┐
│  Stage 4      │
│  tf plan      │──── Real plan against AWS (read-only IAM)
└───────┬───────┘     Output: tfplan.json
        ▼
┌───────────────┐
│  Stage 5      │
│  OPA eval     │──── Custom NIST 800-53 policy evaluation
└───────┬───────┘     Output: opa-results.txt
        ▼
┌───────────────┐
│  Stage 6      │
│  Report       │──── Markdown compliance report generation
└───────┬───────┘     Output: compliance-report.md
        ▼
┌───────────────┐
│  Stage 7      │
│  PR Comment   │──── Posts report directly on the PR
└───────┬───────┘
        ▼
┌───────────────┐
│  Gate         │
│  Pass/Fail    │──── Fails if new violations beyond baseline
└───────────────┘
```

## NIST 800-53 Policy Coverage

### Custom OPA Policies

| Policy | Control | What It Enforces |
|--------|---------|-----------------|
| `s3_encryption.rego` | SC-28 | S3 buckets must have server-side encryption configured |
| `s3_public_access.rego` | AC-3 | S3 buckets must block all public access |
| `iam_no_wildcards.rego` | AC-6 | IAM policies must not use wildcard (*) actions |
| `cloudtrail_encryption.rego` | AU-9 | CloudTrail must use KMS encryption |
| `vpc_restricted_ingress.rego` | SC-7 | No unrestricted ingress on sensitive ports |
| `logging_enabled.rego` | AU-2 | CloudTrail logging must be enabled |
| `tags_required.rego` | CM-8 | All resources must have required compliance tags |

### Checkov Checks (17 scoped via .checkov.yaml)

| Family | Check IDs | Coverage |
|--------|-----------|----------|
| SC (Encryption) | CKV_AWS_19, 145, 35, 158 | S3, CloudTrail, CloudWatch KMS |
| AC (Access) | CKV_AWS_53, 54, 55, 56, 274, 289, 290, 355 | S3 public access, IAM least privilege |
| AU (Audit) | CKV_AWS_252, 338 | CloudTrail SNS, log retention |
| SC (Network) | CKV_AWS_130, 231 | Subnet public IP, NACL RDP |
| CM (Config) | CKV_AWS_300 | S3 lifecycle |

Full policy mapping: [POLICY_MAPPING.md](./docs/POLICY_MAPPING.md)

## Quick Start

### Run Locally

```bash
git clone https://github.com/01alexjohnson-hub/Cloud_Engineering_Projects.git
cd Cloud_Engineering_Projects/compliance-cicd-pipeline

# Install tools
brew install checkov opa
curl -sL https://github.com/terraform-linters/tflint/releases/latest/download/tflint_darwin_arm64.zip -o tflint.zip && unzip tflint.zip && sudo mv tflint /usr/local/bin/

# Run scans
cd terraform-sample
tflint --init && tflint
terraform init -backend=false && terraform validate
checkov -d . --config-file ../.checkov.yaml --compact

# Generate plan and run OPA
terraform plan -out=tfplan.binary -input=false
terraform show -json tfplan.binary > tfplan.json
cd ..
opa eval -d policies/opa/ -i terraform-sample/tfplan.json "data.terraform" --format raw
```

### Pipeline (Automatic)

Push to a branch, open a PR against `main` — the pipeline runs automatically. Requires GitHub Secrets:

| Secret | Purpose |
|--------|---------|
| `AWS_ACCESS_KEY_ID` | Read-only IAM user for terraform plan |
| `AWS_SECRET_ACCESS_KEY` | Read-only IAM user for terraform plan |

## Project Structure

```
compliance-cicd-pipeline/
├── policies/
│   └── opa/                    7 custom Rego policies
│       ├── s3_encryption.rego
│       ├── s3_public_access.rego
│       ├── iam_no_wildcards.rego
│       ├── cloudtrail_encryption.rego
│       ├── vpc_restricted_ingress.rego
│       ├── logging_enabled.rego
│       └── tags_required.rego
├── scripts/
│   └── generate_report.py      Compliance report generator
├── terraform-sample/            Project 1 Terraform (scan target)
├── docs/
│   ├── POLICY_MAPPING.md        Policy → control mapping
│   └── screenshots/             Demo PR screenshots
├── .checkov.yaml                Scoped Checkov configuration
└── .github/workflows/
    └── compliance-scan.yml      GitHub Actions pipeline
```

## Scan Results (Baseline)

Scanning the [FedRAMP Landing Zone](../fedramp-aws-landing-zone/) Terraform as sample code:

| Scanner | Passed | Failed | Notes |
|---------|--------|--------|-------|
| tflint | Clean | 0 | No linting issues |
| terraform validate | Valid | 0 | Configuration is syntactically correct |
| Checkov | 24 | 16 | Free-tier gaps (KMS, log retention, IAM breadth) |
| OPA | 5 | 2 | AU-9 (CloudTrail KMS), AC-6 (IAM wildcards) |
| **Combined** | **30** | **18** | **62.5% pass rate** |

Baseline failures are documented free-tier constraints — the pipeline's baseline-aware gate accepts these while blocking any new violations.

## Production Improvements

This pipeline is portfolio-ready. Moving it to a production environment, the following enhancements apply:

**OIDC federation instead of long-lived keys** — The current setup uses IAM access keys stored as GitHub Secrets. Production should use GitHub's OIDC provider to assume an IAM role with short-lived session tokens. No secrets to rotate, no keys to leak. This is the current AWS/GitHub best practice for CI/CD authentication.

**Branch protection rules** — Require the compliance scan to pass before merging. Currently the gate fails the job, but GitHub still allows the merge. Adding a branch protection rule that requires the `NIST 800-53 Compliance Scan` check to pass makes the gate enforceable.

**Expanded OPA policy set** — The current 7 policies cover the highest-impact controls. A production set would expand to cover all applicable control families, with policies organized by family and tested against mock plan fixtures.

**Notification integration** — Slack or email alerts when the pipeline blocks a deployment, so the security team has visibility without watching GitHub.

## License

Apache 2.0 — see [LICENSE](./LICENSE)
