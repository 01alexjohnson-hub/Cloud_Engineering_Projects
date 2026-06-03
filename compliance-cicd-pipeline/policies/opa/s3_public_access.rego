package terraform.s3_public_access

# NIST 800-53: AC-3 (Access Enforcement)
# S3 buckets must block all public access

import input as tfplan

resources := [r |
    r := tfplan.planned_values.root_module.child_modules[_].resources[_]
]

public_access_blocks := [r |
    r := resources[_]
    r.type == "aws_s3_bucket_public_access_block"
]

deny contains msg if {
    count(public_access_blocks) == 0
    msg := "No S3 public access block configuration found [AC-3]"
}

deny contains msg if {
    block := public_access_blocks[_]
    block.values.block_public_acls != true
    msg := "S3 public access block must have block_public_acls set to true [AC-3]"
}

deny contains msg if {
    block := public_access_blocks[_]
    block.values.block_public_policy != true
    msg := "S3 public access block must have block_public_policy set to true [AC-3]"
}

deny contains msg if {
    block := public_access_blocks[_]
    block.values.ignore_public_acls != true
    msg := "S3 public access block must have ignore_public_acls set to true [AC-3]"
}

deny contains msg if {
    block := public_access_blocks[_]
    block.values.restrict_public_buckets != true
    msg := "S3 public access block must have restrict_public_buckets set to true [AC-3]"
}
