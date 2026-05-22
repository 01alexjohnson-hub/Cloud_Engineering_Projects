# FedRAMP-Ready AWS Landing Zone

Terraform landing zone that deploys a multi-account AWS Organization with FedRAMP security guardrails — deployed to a live AWS account and validated against NIST 800-53.

**77 resources | 7 modules | 17 NIST 800-53 controls | 8 control families**

### Built With

`Terraform` `AWS Organizations` `Service Control Policies` `CloudTrail` `GuardDuty` `Security Hub` `AWS Config` `VPC` `IAM` `S3` `CloudWatch`

---

## What This Proves

Most cloud engineers can build infrastructure. Most compliance consultants can assess it. This project does both — every Terraform resource maps to a NIST 800-53 control with a written rationale for *why* that configuration satisfies the requirement.

Built by a cloud engineer with FedRAMP 3PAO assessment experience (Coalfire). Security isn't bolted on after — it's the architecture.

## Key Design Decisions

**Permission boundaries over broad IAM policies** — Even the admin role has a ceiling. AdministratorAccess is attached but the permission boundary clips it: no modifying the boundary itself, no acting outside FedRAMP regions, no leaving the org. This is what you show an assessor to prove AC-6.

**Security group chaining, not CIDR rules** — The ALB, App, and Data tiers reference each other by security group ID, not IP range. Traffic flows ALB (443) → App (8080) → Data (5432) with no lateral movement. If a tier is compromised, the blast radius stops at the next security group boundary.

**SCPs as the immovable guardrail** — Five Service Control Policies enforce the rules that even account admins can't override: no root account usage, no non-FedRAMP regions, no disabling CloudTrail/GuardDuty, no unencrypted or public S3. These are the compliance controls that survive human error.

## Deployed and Validated

This was deployed to a live AWS account, scored by Security Hub's automated NIST 800-53 checks, then destroyed.

| | |
|---|---|
| **Resources deployed** | 77 across 7 modules |
| **NIST 800-53 score** | 44% (20/45 controls passed) |
| **Score explanation** | Expected for free-tier — remaining controls need production services (ALB/TLS, WAF, KMS CMKs, NAT Gateway). Cost decisions, not design gaps. |
| **Full evidence** | [Screenshots](./docs/Screenshots/) from the deploy session |
| **Control mapping** | [CONTROL_MAPPING.md](./CONTROL_MAPPING.md) — every resource → control |

---

## Architecture

```
AWS Organization
├── Management Account
│   ├── 5 Service Control Policies (guardrails even admins can't override)
│   ├── AWS Config (6 rules: encryption, MFA, SSH restrictions)
│   └── IAM Baseline (permission boundaries + MFA-required roles)
├── Security OU
│   ├── CloudTrail (org-wide, multi-region, tamper-evident)
│   ├── GuardDuty (ML threat detection across CloudTrail, VPC, DNS)
│   ├── Security Hub (NIST 800-53 automated scoring)
│   └── Centralized Logs (encrypted S3, versioned, lifecycle to Glacier)
└── Workloads OU
    └── VPC (2-AZ, public/private subnets, 3-tier security groups, NACLs, flow logs)
```

## NIST 800-53 Control Coverage

| Family | Controls |
|--------|----------|
| Access Control (AC) | AC-2, AC-4, AC-6, AC-17 |
| Audit & Accountability (AU) | AU-2, AU-3, AU-6, AU-9, AU-11 |
| Security Assessment (CA) | CA-7 |
| Configuration Management (CM) | CM-6, CM-7 |
| Identification & Auth (IA) | IA-2 |
| Risk Assessment (RA) | RA-5 |
| System & Comms Protection (SC) | SC-7, SC-28 |
| System & Info Integrity (SI) | SI-4 |

Full resource-level mapping with rationale: [CONTROL_MAPPING.md](./CONTROL_MAPPING.md)

## Quick Start

```bash
git clone https://github.com/01alexjohnson-hub/Cloud_Engineering_Projects.git
cd Cloud_Engineering_Projects/fedramp-aws-landing-zone

# Bootstrap remote state (one-time)
chmod +x scripts/bootstrap-state.sh && ./scripts/bootstrap-state.sh

# Configure and validate
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform validate && terraform plan
```

Deploy costs ~$5 for a proof session, then destroy. Development is $0 via `terraform plan`.

## Project Structure

```
modules/
├── organizations/    7 resources — AWS Orgs + 5 SCPs
├── logging/          7 resources — Encrypted S3 log bucket + lifecycle
├── cloudtrail/       4 resources — Org-wide multi-region audit trail
├── guardduty/        1 resource  — ML-based threat detection
├── security-hub/     3 resources — NIST 800-53 compliance dashboard
├── config-rules/    12 resources — Config recorder + 6 managed rules
├── vpc/             29 resources — 2-AZ 3-tier network + flow logs
└── iam/              5 resources — Permission boundaries + MFA roles
                     ── ──────────
                     77 total
```

## Remediation Roadmap

The path from 44% to full compliance — remaining controls need production-tier services:

| Gap | What's Needed | Why It's Not Here |
|-----|--------------|-------------------|
| SC-8 | ACM + ALB with TLS (~$16/mo) | HTTPS termination for transmission confidentiality |
| SC-7 (WAF) | AWS WAF (~$5/mo) | Web application firewall on ALB |
| SC-28 (KMS) | KMS CMKs ($1/mo per key) | Customer-managed key rotation |
| AC-4 (NAT) | NAT Gateway (~$32/mo) | Private subnet outbound access |
| AC-2(1) | AWS SSO / Identity Center | Automated account provisioning |
| IA-5 | IAM password policy | Authenticator management |

These are cost and operational decisions documented by design — not missing capabilities.

## License

Apache 2.0 — see [LICENSE](./LICENSE)
