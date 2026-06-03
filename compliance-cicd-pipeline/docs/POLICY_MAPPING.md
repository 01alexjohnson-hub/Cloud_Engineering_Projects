# NIST 800-53 Policy Mapping

Maps each OPA policy to its NIST 800-53 control and describes what it enforces.

| # | Policy File | NIST Control | Control Name | What It Enforces |
|---|------------|-------------|-------------|-----------------|
| 1 | s3_encryption.rego | SC-28 | Protection of Information at Rest | S3 buckets must have server-side encryption configured |
| 2 | s3_public_access.rego | AC-3 | Access Enforcement | S3 buckets must block all public access |
| 3 | iam_no_wildcards.rego | AC-6 | Least Privilege | IAM policies must not use wildcard (*) actions |
| 4 | cloudtrail_encryption.rego | AU-9 | Protection of Audit Information | CloudTrail must use KMS encryption |
| 5 | vpc_no_default_sg.rego | SC-7 | Boundary Protection | Default security groups must have no inbound/outbound rules |
| 6 | logging_enabled.rego | AU-2 | Audit Events | CloudTrail logging must be enabled |
| 7 | tags_required.rego | CM-8 | Information System Component Inventory | All resources must have required compliance tags |
