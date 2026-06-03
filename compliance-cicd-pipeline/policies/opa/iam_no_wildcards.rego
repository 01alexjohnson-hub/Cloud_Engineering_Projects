package terraform.iam_no_wildcards

# NIST 800-53: AC-6 (Least Privilege)
# IAM policies must not use wildcard (*) actions

import input as tfplan

resources := [r |
    r := tfplan.planned_values.root_module.child_modules[_].resources[_]
]

iam_policies := [r |
    r := resources[_]
    r.type in ["aws_iam_policy", "aws_iam_role_policy"]
    r.values.policy
]

deny contains msg if {
    pol := iam_policies[_]
    doc := json.unmarshal(pol.values.policy)
    statement := doc.Statement[_]
    action := statement.Action[_]
    action == "*"
    msg := sprintf("IAM policy '%s' uses wildcard (*) action [AC-6]", [pol.name])
}

deny contains msg if {
    pol := iam_policies[_]
    doc := json.unmarshal(pol.values.policy)
    statement := doc.Statement[_]
    statement.Action == "*"
    msg := sprintf("IAM policy '%s' uses wildcard (*) action [AC-6]", [pol.name])
}
