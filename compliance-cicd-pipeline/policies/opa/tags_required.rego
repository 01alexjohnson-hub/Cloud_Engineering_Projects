package terraform.tags_required

# NIST 800-53: CM-8 (Information System Component Inventory)
# All resources must have required compliance tags

import input as tfplan

resources := [r |
    r := tfplan.planned_values.root_module.child_modules[_].resources[_]
]

required_tags := ["Environment", "ManagedBy", "Project", "Compliance"]

taggable_resources := [r |
    r := resources[_]
    r.values.tags_all
]

deny contains msg if {
    r := taggable_resources[_]
    tag := required_tags[_]
    not r.values.tags_all[tag]
    msg := sprintf("Resource '%s.%s' is missing required tag '%s' [CM-8]", [r.type, r.name, tag])
}
