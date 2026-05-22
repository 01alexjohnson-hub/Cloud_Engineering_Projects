# NIST 800-53 Control Mapping

Every Terraform resource in this landing zone maps to one or more NIST 800-53 Rev 5 controls. This document provides the complete mapping, organized by control family.

**Total: 77 Terraform resources | 17 NIST 800-53 controls | 8 control families**

**Proof of deployment:** Security Hub automated compliance check scored **44% (20/45 controls passed)** against the full NIST 800-53 standard on first deploy. Remaining controls require production-tier services documented in the [Remediation Roadmap](#remediation-roadmap) below.

---

## Access Control (AC)

### AC-2 — Account Management

Ensures accounts are properly managed, authorized, and monitored.

| Resource | Module | How It Satisfies AC-2 |
|----------|--------|----------------------|
| `aws_organizations_organization.this` | organizations | Centralizes account management under a single org with full SCP enforcement |
| `aws_organizations_organizational_unit.security` | organizations | Segments security accounts into a dedicated OU with distinct policies |
| `aws_organizations_organizational_unit.workloads` | organizations | Segments workload accounts into a dedicated OU |
| `aws_organizations_policy.deny_root_account` | organizations | Prevents root account usage — root credentials bypass normal access controls |
| `aws_organizations_policy.deny_leave_org` | organizations | Prevents accounts from escaping organizational controls |
| `aws_iam_role.readonly` | iam | Provides scoped read-only access for auditors instead of shared credentials |

### AC-4 — Information Flow Enforcement

Controls the flow of information between systems and network segments.

| Resource | Module | How It Satisfies AC-4 |
|----------|--------|----------------------|
| `aws_organizations_policy.enforce_s3_security` | organizations | Blocks public S3 access and enforces encryption on data flows |
| `aws_security_group.alb` | vpc | Restricts inbound to HTTPS (443) only — no other protocols reach the public tier |
| `aws_security_group.app` | vpc | App tier accepts traffic only from ALB security group — no direct internet access |
| `aws_security_group.data` | vpc | Data tier accepts traffic only from App security group — two hops from the internet |
| `aws_vpc_security_group_ingress_rule.*` | vpc | Explicit ingress rules enforce tier-to-tier flow (ALB→App→Data) |
| `aws_vpc_security_group_egress_rule.*` | vpc | Explicit egress rules prevent lateral movement between tiers |
| `aws_network_acl.public` | vpc | Stateless subnet-level firewall allowing only 80/443 and ephemeral ports |
| `aws_network_acl.private` | vpc | Restricts private subnet traffic to VPC CIDR and HTTPS outbound only |
| `aws_config_config_rule.restricted_ssh` | config-rules | Detects security groups allowing unrestricted SSH (0.0.0.0/0 on port 22) |

### AC-6 — Least Privilege

Ensures users and systems operate with the minimum permissions necessary.

| Resource | Module | How It Satisfies AC-6 |
|----------|--------|----------------------|
| `aws_organizations_policy.*` (all SCPs) | organizations | SCPs enforce an organization-wide permission ceiling that even account admins cannot override |
| `aws_iam_policy.permission_boundary` | iam | Caps the maximum permissions any role can have — even AdministratorAccess is clipped |
| `aws_iam_role.admin` | iam | Admin role requires MFA to assume and is bounded by the permission boundary |
| `aws_iam_role.readonly` | iam | Auditor access limited to ReadOnlyAccess + SecurityAudit — cannot modify resources |
| `aws_iam_role_policy_attachment.admin` | iam | AdministratorAccess attached but effective permissions are intersection with boundary |

### AC-17 — Remote Access

Controls and monitors remote access to the information system.

| Resource | Module | How It Satisfies AC-17 |
|----------|--------|----------------------|
| `aws_security_group.app` | vpc | No SSH (port 22) ingress — remote access is SSM Session Manager only |
| `aws_security_group.data` | vpc | No direct access from internet — only reachable through app tier |
| `aws_network_acl.private` | vpc | Private subnets have no inbound from internet — physical network isolation |

---

## Audit and Accountability (AU)

### AU-2 — Audit Events

Ensures the system generates audit records for defined events.

| Resource | Module | How It Satisfies AU-2 |
|----------|--------|----------------------|
| `aws_cloudtrail.org_trail` | cloudtrail | Records every API call across all accounts and all regions |
| `aws_organizations_policy.protect_audit_logging` | organizations | SCP prevents anyone from disabling CloudTrail or GuardDuty |
| `aws_flow_log.this` | vpc | Captures all network traffic metadata (source, dest, port, accept/reject) |

### AU-3 — Content of Audit Records

Ensures audit records contain sufficient detail for forensic analysis.

| Resource | Module | How It Satisfies AU-3 |
|----------|--------|----------------------|
| `aws_cloudtrail.org_trail` | cloudtrail | Each record includes: who (principal), what (API action), when (timestamp), where (region/IP), outcome (success/error) |

### AU-6 — Audit Review, Analysis, and Reporting

Provides capability to review and analyze audit records.

| Resource | Module | How It Satisfies AU-6 |
|----------|--------|----------------------|
| `aws_cloudwatch_log_group.cloudtrail` | cloudtrail | Enables real-time search and filtering of CloudTrail events |
| `aws_cloudwatch_log_group.flow_logs` | vpc | Enables real-time search of network traffic logs |
| `aws_iam_role.cloudtrail_cloudwatch` | cloudtrail | Allows CloudTrail to deliver logs to CloudWatch for analysis |

### AU-9 — Protection of Audit Information

Protects audit information from unauthorized access, modification, or deletion.

| Resource | Module | How It Satisfies AU-9 |
|----------|--------|----------------------|
| `aws_s3_bucket.logs` | logging | Centralized, dedicated log bucket — single point of access control |
| `aws_s3_bucket_versioning.logs` | logging | Versioning preserves original log files even if someone modifies them |
| `aws_s3_bucket_server_side_encryption_configuration.logs` | logging | AES-256 encryption at rest for all log data |
| `aws_s3_bucket_public_access_block.logs` | logging | Blocks all public access to audit logs |
| `aws_s3_bucket_policy.logs` | logging | Only CloudTrail service can write; denies unencrypted uploads and HTTP transport |
| `aws_organizations_policy.protect_audit_logging` | organizations | SCP makes CloudTrail and GuardDuty untouchable — even account admins can't disable them |

### AU-11 — Audit Record Retention

Retains audit records for a defined period consistent with records retention policy.

| Resource | Module | How It Satisfies AU-11 |
|----------|--------|----------------------|
| `aws_s3_bucket_lifecycle_configuration.logs` | logging | Automated tiering: Standard → Infrequent Access (90 days) → Glacier (365 days) |
| `aws_cloudwatch_log_group.cloudtrail` | cloudtrail | 90-day retention in CloudWatch for real-time access |
| `aws_cloudwatch_log_group.flow_logs` | vpc | 90-day retention for VPC flow log data |

---

## Security Assessment and Authorization (CA)

### CA-7 — Continuous Monitoring

Establishes a continuous monitoring program for the information system.

| Resource | Module | How It Satisfies CA-7 |
|----------|--------|----------------------|
| `aws_securityhub_account.this` | security-hub | Central dashboard aggregating findings from all security services |
| `aws_securityhub_standards_subscription.nist_800_53` | security-hub | Automated compliance scoring against NIST 800-53 Rev 5 |
| `aws_securityhub_standards_subscription.aws_foundational` | security-hub | AWS Foundational Security Best Practices checks |
| `aws_config_configuration_recorder.this` | config-rules | Continuously records all resource configurations |
| `aws_config_delivery_channel.this` | config-rules | Delivers configuration snapshots to S3 every 6 hours |
| `aws_config_config_rule.*` (all 6 rules) | config-rules | Automated compliance checks: encryption, MFA, SSH restrictions |

---

## Configuration Management (CM)

### CM-6 — Configuration Settings

Establishes mandatory configuration settings for IT products.

| Resource | Module | How It Satisfies CM-6 |
|----------|--------|----------------------|
| `aws_config_config_rule.s3_encryption` | config-rules | Enforces S3 server-side encryption as a baseline setting |
| `aws_config_config_rule.ebs_encryption` | config-rules | Enforces EBS volume encryption |
| `aws_config_config_rule.rds_encryption` | config-rules | Enforces RDS storage encryption |
| `aws_config_config_rule.restricted_ssh` | config-rules | Enforces no open SSH in security groups |
| `aws_config_configuration_recorder.this` | config-rules | Records configuration drift from baseline |

### CM-7 — Least Functionality

Restricts the system to only essential capabilities.

| Resource | Module | How It Satisfies CM-7 |
|----------|--------|----------------------|
| `aws_organizations_policy.restrict_regions` | organizations | Blocks all activity outside FedRAMP-authorized regions (us-east-1, us-east-2, us-west-2) |

---

## Identification and Authentication (IA)

### IA-2 — Identification and Authentication (Organizational Users)

Uniquely identifies and authenticates organizational users.

| Resource | Module | How It Satisfies IA-2 |
|----------|--------|----------------------|
| `aws_iam_role.admin` | iam | Requires MFA for role assumption — no MFA, no access |
| `aws_iam_role.readonly` | iam | Requires MFA for role assumption |
| `aws_config_config_rule.iam_mfa` | config-rules | Detects IAM users without MFA enabled |
| `aws_config_config_rule.root_mfa` | config-rules | Detects if root account lacks MFA |

---

## Risk Assessment (RA)

### RA-5 — Vulnerability Monitoring and Scanning

Monitors and scans for vulnerabilities in the information system.

| Resource | Module | How It Satisfies RA-5 |
|----------|--------|----------------------|
| `aws_guardduty_detector.this` | guardduty | Continuously analyzes CloudTrail, VPC Flow Logs, and DNS logs for threats, anomalies, and indicators of compromise |

---

## System and Communications Protection (SC)

### SC-7 — Boundary Protection

Monitors and controls communications at the system boundary.

| Resource | Module | How It Satisfies SC-7 |
|----------|--------|----------------------|
| `aws_vpc.this` | vpc | Network isolation boundary — all resources exist within a defined CIDR |
| `aws_internet_gateway.this` | vpc | Single controlled entry point from internet to VPC |
| `aws_subnet.public` (x2) | vpc | Public tier in 2 AZs — only ALBs live here |
| `aws_subnet.private` (x2) | vpc | Private tier in 2 AZs — no direct internet access |
| `aws_route_table.public` | vpc | Routes public subnet traffic through IGW |
| `aws_route_table.private` | vpc | No default route to internet — fully isolated |
| `aws_network_acl.public` | vpc | Stateless firewall: allows 80, 443, ephemeral ports only |
| `aws_network_acl.private` | vpc | Stateless firewall: VPC-internal traffic and HTTPS outbound only |

### SC-28 — Protection of Information at Rest

Protects the confidentiality and integrity of information at rest.

| Resource | Module | How It Satisfies SC-28 |
|----------|--------|----------------------|
| `aws_s3_bucket_server_side_encryption_configuration.logs` | logging | AES-256 server-side encryption on all log data |
| `aws_organizations_policy.enforce_s3_security` | organizations | SCP denies any S3 PutObject without server-side encryption |
| `aws_config_config_rule.s3_encryption` | config-rules | Continuous check that all S3 buckets have encryption enabled |
| `aws_config_config_rule.ebs_encryption` | config-rules | Continuous check that all EBS volumes are encrypted |
| `aws_config_config_rule.rds_encryption` | config-rules | Continuous check that all RDS instances are encrypted |

---

## System and Information Integrity (SI)

### SI-4 — System Monitoring

Monitors the information system to detect attacks, indicators of potential attacks, and unauthorized connections.

| Resource | Module | How It Satisfies SI-4 |
|----------|--------|----------------------|
| `aws_guardduty_detector.this` | guardduty | ML-based threat detection analyzing CloudTrail, VPC Flow Logs, DNS queries |
| `aws_organizations_policy.protect_audit_logging` | organizations | SCP prevents disabling monitoring services (CloudTrail, GuardDuty) |
| `aws_flow_log.this` | vpc | Captures all network traffic for anomaly detection |
| `aws_cloudtrail.org_trail` | cloudtrail | Records all API activity for behavioral analysis |

---

## Remediation Roadmap

Controls that did not pass the automated Security Hub check fall into three categories:

### Production Services (not deployed for cost reasons)

| Control Gap | Required Service | Estimated Cost | Notes |
|------------|-----------------|----------------|-------|
| SC-8 (Transmission Confidentiality) | ACM + ALB with TLS | ~$16/mo (ALB) | ALB with ACM certificate for HTTPS termination |
| SC-7 (Boundary Protection — WAF) | AWS WAF | ~$5/mo + request fees | Web application firewall on ALB |
| SC-28 (KMS encryption) | KMS Customer Managed Keys | $1/mo per key | Replace SSE-S3 with SSE-KMS for key rotation control |
| AC-4 (NAT Gateway) | NAT Gateway | ~$32/mo | Private subnet outbound internet access |

### Operational Controls (require human processes)

| Control Gap | What's Needed | Notes |
|------------|--------------|-------|
| AC-2(1) (Automated account management) | AWS SSO / Identity Center | Federated identity with automated provisioning |
| IA-5 (Authenticator management) | Password policy + rotation | IAM password policy resource + SCP enforcement |
| AT-2 (Security awareness training) | Training program | Organizational control, not infrastructure |
| PL-2 (System security plan) | SSP document | Documentation deliverable |

### Already Addressed (may need Security Hub rule tuning)

Some controls that show as "failed" are actually satisfied by resources we deployed but Security Hub checks a stricter interpretation (e.g., requiring KMS CMKs instead of SSE-S3, or requiring VPC endpoints instead of HTTPS egress). These are configuration-level adjustments, not missing capabilities.
