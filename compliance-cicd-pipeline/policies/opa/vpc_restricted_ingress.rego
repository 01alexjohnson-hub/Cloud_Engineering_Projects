package terraform.vpc_restricted_ingress

# NIST 800-53: SC-7 (Boundary Protection)
# Security groups must not allow unrestricted ingress on sensitive ports

import input as tfplan

resources := [r |
    r := tfplan.planned_values.root_module.child_modules[_].resources[_]
]

ingress_rules := [r |
    r := resources[_]
    r.type == "aws_vpc_security_group_ingress_rule"
]

sensitive_ports := [22, 3389, 3306, 5432, 1433, 27017]

deny contains msg if {
    rule := ingress_rules[_]
    rule.values.cidr_ipv4 == "0.0.0.0/0"
    port := sensitive_ports[_]
    rule.values.from_port <= port
    rule.values.to_port >= port
    msg := sprintf("Ingress rule '%s' allows 0.0.0.0/0 on sensitive port %d [SC-7]", [rule.name, port])
}
