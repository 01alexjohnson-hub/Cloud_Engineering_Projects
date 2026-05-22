# Changelog

All notable changes to this project will be documented in this file. Format based on [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] — 2026-05-22

First complete release. 77 Terraform resources across 7 modules, mapped to 17 NIST 800-53 Rev 5 controls. Proof deployed to AWS account and validated with Security Hub (44% / 20 of 45 controls passed).

### Added

**Organizations Module (Phase 1-2)**
- AWS Organization with full SCP enforcement
- Security OU and Workloads OU
- 5 Service Control Policies: deny root usage, deny leave org, restrict regions to FedRAMP-authorized (us-east-1, us-east-2, us-west-2), enforce S3 encryption + block public access, protect audit logging (CloudTrail/GuardDuty)

**Logging Module (Phase 3)**
- Centralized S3 log bucket with account-ID-based naming
- Versioning enabled for tamper evidence
- AES-256 server-side encryption at rest
- Public access fully blocked
- Bucket policy restricting writes to CloudTrail service only, denying unencrypted uploads and HTTP transport
- Lifecycle rules: Standard to Infrequent Access at 90 days, Glacier at 365 days

**CloudTrail Module (Phase 3)**
- Organization-wide, multi-region CloudTrail trail
- Log file validation enabled for tamper detection
- CloudWatch Logs integration with 90-day retention
- IAM role for CloudTrail-to-CloudWatch delivery
- Captures all management events (read + write) across all accounts

**GuardDuty Module (Phase 4)**
- GuardDuty detector with S3 data source enabled
- ML-based threat detection analyzing CloudTrail, VPC Flow Logs, and DNS logs

**Security Hub Module (Phase 4)**
- Security Hub account activation
- NIST 800-53 Rev 5 standards subscription
- AWS Foundational Security Best Practices standards subscription

**Config Rules Module (Phase 4)**
- AWS Config recorder (all resource types + global resources)
- Config delivery channel with 6-hour snapshots to centralized log bucket
- 6 managed Config rules: S3 encryption, EBS encryption, RDS encryption, IAM user MFA, root account MFA, restricted SSH

**VPC Module (Phase 5)**
- VPC with configurable CIDR (default 10.0.0.0/16)
- 2-AZ architecture with public and private subnets
- Internet Gateway with public route table
- Private route table with no internet route (full isolation)
- Public NACL allowing ports 80, 443, and ephemeral ports only
- Private NACL restricting to VPC CIDR and HTTPS outbound
- 3-tier security group chaining: ALB (443 in) to App (8080) to Data (5432)
- VPC Flow Logs capturing all traffic to CloudWatch (90-day retention)

**IAM Module (Phase 5)**
- Permission boundary policy capping maximum permissions for all roles
- Admin role: AdministratorAccess bounded by permission boundary, MFA required, 1-hour max session
- ReadOnly role: ReadOnlyAccess + SecurityAudit, MFA required, bounded by permission boundary
- Region restriction enforced at IAM level (FedRAMP regions only)

**Documentation (Phase 7)**
- CONTROL_MAPPING.md: every resource mapped to its NIST 800-53 control with rationale
- README with architecture diagram, proof deploy results, and remediation roadmap
- CHANGELOG.md
- Proof-of-deployment screenshots in docs/Screenshots/

**Infrastructure**
- Terraform remote state configuration (S3 + DynamoDB)
- Bootstrap script for one-time state setup
- terraform.tfvars.example with documented variables

### Proof Deploy Results
- 77 resources created successfully
- Security Hub NIST 800-53 automated score: 44% (20/45 controls passed)
- Remaining controls require production-tier services documented in remediation roadmap
- All resources destroyed after validation to avoid ongoing costs
