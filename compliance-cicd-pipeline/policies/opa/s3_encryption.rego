package terraform.s3

# NIST 800-53: SC-28 (Protection of Information at Rest)
# S3 buckets must have server-side encryption configured

import input as tfplan

# Collect all resources across all child modules
resources := [r |
    r := tfplan.planned_values.root_module.child_modules[_].resources[_]
]

# Find all S3 buckets
s3_buckets := [r |
    r := resources[_]
    r.type == "aws_s3_bucket"
]

# Find all encryption configurations
encryption_configs := [r |
    r := resources[_]
    r.type == "aws_s3_bucket_server_side_encryption_configuration"
]

# Deny if any S3 bucket has no matching encryption config
deny contains msg if {
    bucket := s3_buckets[_]
    count(encryption_configs) == 0
    msg := sprintf("S3 bucket '%s' has no server-side encryption configuration [SC-28]", [bucket.name])
}
