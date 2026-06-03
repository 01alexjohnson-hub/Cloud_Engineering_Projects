package terraform.logging_enabled

# NIST 800-53: AU-2 (Audit Events)
# CloudTrail logging must be enabled

import input as tfplan

resources := [r |
    r := tfplan.planned_values.root_module.child_modules[_].resources[_]
]

cloudtrails := [r |
    r := resources[_]
    r.type == "aws_cloudtrail"
]

deny contains msg if {
    count(cloudtrails) == 0
    msg := "No CloudTrail resource found - audit logging is required [AU-2]"
}

deny contains msg if {
    trail := cloudtrails[_]
    trail.values.enable_logging != true
    msg := sprintf("CloudTrail '%s' does not have logging enabled [AU-2]", [trail.values.name])
}
