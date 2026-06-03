package terraform.cloudtrail_encryption

# NIST 800-53: AU-9 (Protection of Audit Information)
# CloudTrail must use KMS encryption

import input as tfplan

resources := [r |
    r := tfplan.planned_values.root_module.child_modules[_].resources[_]
]

cloudtrails := [r |
    r := resources[_]
    r.type == "aws_cloudtrail"
]

deny contains msg if {
    trail := cloudtrails[_]
    trail.values.kms_key_id == null
    msg := sprintf("CloudTrail '%s' is not encrypted with KMS [AU-9]", [trail.values.name])
}
