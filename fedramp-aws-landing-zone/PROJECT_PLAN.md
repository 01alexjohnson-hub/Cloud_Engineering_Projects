# Project 1: FedRAMP-Ready AWS Landing Zone — Build Plan

## Overview

A production-grade Terraform module that deploys a multi-account AWS Organization with FedRAMP-aligned security guardrails. Every resource maps back to a NIST 800-53 control, bridging the gap between compliance requirements and actual infrastructure.

**Repo name:** `fedramp-aws-landing-zone`
**Budget:** $0 development (terraform plan validation) → ~$5 for one proof deploy + screenshots → destroy
**Timeline:** Build in phases, each phase is a meaningful commit

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                     AWS Organization                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Management   │  │  Security    │  │  Workload    │          │
│  │  Account      │  │  Account     │  │  Account     │          │
│  │  (Org root)   │  │  (Log arch.) │  │  (App env)   │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
│  ┌──────┴───────┐  ┌──────┴───────┐  ┌──────┴───────┐          │
│  │ SCPs         │  │ CloudTrail   │  │ VPC          │          │
│  │ IAM Baseline │  │ GuardDuty    │  │ Security Grps│          │
│  │ Config Rules │  │ Security Hub │  │ EC2/RDS      │          │
│  │              │  │ Central Logs │  │ KMS          │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Free Tier Strategy

### Safe (No Cost)
| Service | Free Tier Allowance | Our Usage |
|---------|-------------------|-----------|
| AWS Organizations | Free | Multi-account structure |
| IAM | Free | Roles, policies, permission boundaries |
| SCPs | Free | Org-level guardrails |
| S3 | 5GB, 20K GET, 2K PUT | Log bucket, state bucket |
| CloudWatch Logs | 5GB ingestion | VPC flow logs, CloudTrail |
| AWS Config | Free (first 25 rule evaluations/region) | Config Rules |
| DynamoDB | 25GB | Terraform state locking |
| VPC | Free | Subnets, route tables, NACLs |
| Security Groups | Free | Firewall rules |

### Caution (Deploy Briefly, Then Destroy)
| Service | Cost | Strategy |
|---------|------|----------|
| GuardDuty | 30-day free trial | Enable during proof session, screenshot, disable |
| Security Hub | 30-day free trial | Same — enable, validate, screenshot, disable |
| CloudTrail | First trail free, S3 costs | Minimal — one trail, small log volume |
| NAT Gateway | ~$0.045/hr | Skip for dev; document in architecture as "production addition" |
| KMS | $1/mo per CMK | Use AWS-managed keys for dev; custom CMK for proof session |
| RDS | 750 hrs db.t3.micro | Single-AZ only, deploy briefly |

### Development Approach
- **Phase 1-5:** Build and validate with `terraform validate` + `terraform plan` (no cost)
- **Phase 6:** One proof deploy session (~$5), capture screenshots, then `terraform destroy`
- **Phase 7:** Polish docs with real screenshots

---

## Build Phases

### Phase 1: Foundation (You Are Here)
**What:** Project scaffold, remote state config, provider setup
**Files:**
- `main.tf` — Root module, provider config
- `variables.tf` — Input variables with sensible defaults
- `outputs.tf` — Key outputs (account IDs, VPC IDs, etc.)
- `versions.tf` — Terraform and provider version constraints
- `backend.tf` — S3 + DynamoDB remote state
- `terraform.tfvars.example` — Example variable values
- `.gitignore` — Terraform-specific ignores
- `README.md` — Project overview (will grow each phase)

**NIST 800-53 controls addressed:** None yet (infrastructure for infrastructure)

**Commit message:** `feat: initial project scaffold with remote state configuration`

---

### Phase 2: Organizations & SCPs
**What:** AWS Organizations structure with Service Control Policies
**Module:** `modules/organizations/`
**Resources:**
- `aws_organizations_organization` — Enable Organizations
- `aws_organizations_organizational_unit` — Security OU, Workload OU
- `aws_organizations_account` — Security account, Workload account
- `aws_organizations_policy` — SCPs for guardrails

**SCPs to implement:**
- Deny root account usage
- Deny leaving the organization
- Restrict regions to us-east-1, us-east-2, us-west-2 (FedRAMP-authorized)
- Deny disabling CloudTrail
- Deny disabling GuardDuty
- Require encryption on S3 buckets
- Deny public S3 access

**NIST 800-53 controls:**
- AC-2 (Account Management) — root account restrictions
- AC-6 (Least Privilege) — SCPs enforce boundaries
- CM-7 (Least Functionality) — region restrictions
- AU-2 (Audit Events) — prevent disabling audit logs

**Commit message:** `feat: AWS Organizations with FedRAMP-aligned SCPs`

---

### Phase 3: Centralized Logging & Audit
**What:** CloudTrail, centralized S3 log bucket, CloudWatch Logs
**Modules:** `modules/cloudtrail/`, `modules/logging/`
**Resources:**
- `aws_cloudtrail` — Org-wide trail, all regions
- `aws_s3_bucket` — Centralized log bucket with:
  - Versioning enabled
  - Server-side encryption (SSE-S3 or SSE-KMS)
  - Lifecycle rules (transition to IA after 90 days)
  - Bucket policy restricting access to CloudTrail
- `aws_cloudwatch_log_group` — CloudTrail log delivery
- `aws_s3_bucket_public_access_block` — Block all public access

**NIST 800-53 controls:**
- AU-2 (Audit Events) — CloudTrail captures API calls
- AU-3 (Content of Audit Records) — CloudTrail includes who, what, when, where
- AU-6 (Audit Review) — Logs centralized for review
- AU-9 (Protection of Audit Information) — Encryption, versioning, access restrictions
- AU-11 (Audit Record Retention) — Lifecycle policies for retention

**Commit message:** `feat: centralized logging with CloudTrail and encrypted S3`

---

### Phase 4: Threat Detection & Compliance Monitoring
**What:** GuardDuty, Security Hub, AWS Config Rules
**Modules:** `modules/guardduty/`, `modules/security-hub/`, `modules/config-rules/`
**Resources:**
- `aws_guardduty_detector` — Enable threat detection
- `aws_securityhub_account` — Enable Security Hub
- `aws_securityhub_standards_subscription` — Enable NIST 800-53 standard
- `aws_config_configuration_recorder` — Enable Config recording
- `aws_config_delivery_channel` — Deliver to S3
- Custom Config Rules for:
  - S3 buckets must be encrypted
  - EBS volumes must be encrypted
  - RDS instances must be encrypted
  - IAM users must have MFA
  - Security groups must not allow 0.0.0.0/0 on SSH

**NIST 800-53 controls:**
- SI-4 (Information System Monitoring) — GuardDuty
- CA-7 (Continuous Monitoring) — Security Hub + Config Rules
- RA-5 (Vulnerability Scanning) — GuardDuty findings
- CM-6 (Configuration Settings) — Config Rules enforce baselines
- IA-2 (Identification and Authentication) — MFA requirement

**Commit message:** `feat: GuardDuty, Security Hub, and Config Rules for continuous monitoring`

---

### Phase 5: Network & IAM Baseline
**What:** VPC architecture, security groups, IAM roles/policies, permission boundaries
**Modules:** `modules/vpc/`, `modules/iam/`
**Resources:**
- VPC with CIDR 10.0.0.0/16
- Public subnets (10.0.1.0/24, 10.0.2.0/24) — 2 AZs
- Private subnets (10.0.10.0/24, 10.0.20.0/24) — 2 AZs
- Internet Gateway, Route Tables
- NACLs with explicit allow/deny rules
- Security Groups:
  - ALB: allow 443 inbound from 0.0.0.0/0
  - App tier: allow traffic only from ALB SG
  - Data tier: allow traffic only from App SG
- IAM roles:
  - Admin role with permission boundary
  - ReadOnly role for auditors
  - App role (EC2 instance profile) with least privilege
- Permission boundaries to cap maximum permissions

**NIST 800-53 controls:**
- SC-7 (Boundary Protection) — VPC, subnets, NACLs, security groups
- AC-4 (Information Flow Enforcement) — Security group chaining
- AC-6 (Least Privilege) — IAM roles, permission boundaries
- IA-2 (Identification and Authentication) — IAM role-based access
- AC-17 (Remote Access) — No direct SSH; SSM Session Manager only

**Commit message:** `feat: VPC architecture and IAM baseline with permission boundaries`

---

### Phase 6: Proof Deploy & Screenshots
**What:** Deploy the full stack once in real AWS, capture evidence, destroy
**Budget:** ~$5
**Process:**
1. Run `terraform apply` in a clean AWS account
2. Screenshot: Organizations structure in console
3. Screenshot: CloudTrail dashboard showing events
4. Screenshot: GuardDuty findings page (even if empty — shows it's active)
5. Screenshot: Security Hub compliance score against NIST framework
6. Screenshot: Config Rules dashboard with compliance status
7. Screenshot: VPC topology in console
8. Screenshot: `terraform plan` output showing full resource count
9. Run `terraform destroy` — confirm $0 ongoing
10. Save all screenshots to `docs/screenshots/`

**Commit message:** `docs: add proof-of-deployment screenshots`

---

### Phase 7: Documentation & Polish
**What:** README, CONTROL_MAPPING.md, architecture diagram, release tag
**Deliverables:**
- `README.md` — Polished with Quick Start, architecture diagram, module descriptions
- `CONTROL_MAPPING.md` — Every Terraform resource → NIST 800-53 control mapping
- `docs/architecture.png` — Professional diagram (draw.io or Mermaid export)
- `CHANGELOG.md` — Version history
- `LICENSE` — Apache 2.0
- Git tag: `v1.0.0`

**Success criteria from the brief:**
- [ ] Recruiter understands what it does in 60 seconds from the README
- [ ] `terraform validate` and `terraform plan` pass cleanly
- [ ] 15+ NIST 800-53 controls mapped to infrastructure resources
- [ ] Architecture diagram is clear and professional
- [ ] Module is structured for reuse (variables, outputs, sensible defaults)

**Commit message:** `docs: complete documentation with control mapping and architecture diagram`

---

## Control Mapping Preview (15+ controls)

| Control ID | Control Name | Terraform Resource | Module |
|-----------|-------------|-------------------|--------|
| AC-2 | Account Management | organizations_policy (deny root) | organizations |
| AC-4 | Information Flow | security_group (chained rules) | vpc |
| AC-6 | Least Privilege | iam_policy, permission_boundary | iam |
| AC-17 | Remote Access | SSM-only access (no SSH SG rule) | vpc |
| AU-2 | Audit Events | cloudtrail | cloudtrail |
| AU-3 | Content of Audit Records | cloudtrail (data events) | cloudtrail |
| AU-6 | Audit Review | security_hub, cloudwatch | security-hub |
| AU-9 | Protection of Audit Info | s3_bucket (encryption, versioning) | logging |
| AU-11 | Audit Record Retention | s3_lifecycle_rule | logging |
| CA-7 | Continuous Monitoring | config_rules, security_hub | config-rules |
| CM-6 | Configuration Settings | config_rules | config-rules |
| CM-7 | Least Functionality | organizations_policy (region restrict) | organizations |
| IA-2 | Identification & Auth | iam_role, MFA config rule | iam |
| RA-5 | Vulnerability Scanning | guardduty_detector | guardduty |
| SC-7 | Boundary Protection | vpc, nacl, security_group | vpc |
| SC-28 | Protection at Rest | kms_key, s3 encryption | logging |
| SI-4 | System Monitoring | guardduty, cloudwatch | guardduty |

That's 17 controls mapped — exceeds the 15+ target.

---

## Git Strategy

- One branch per phase: `phase-1/foundation`, `phase-2/organizations`, etc.
- PR into `main` with descriptive commit message
- Show real development progression (not one giant commit)
- Tag `v1.0.0` after Phase 7

---

## What's Next

Start Phase 1. Deploy nothing. Build the scaffold and validate.
