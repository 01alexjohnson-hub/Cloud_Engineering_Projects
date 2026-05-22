# -----------------------------------------------------------------------------
# Module: VPC — Network Architecture
# NIST 800-53: SC-7 (Boundary Protection), AC-4 (Information Flow),
#              SI-4 (System Monitoring), AU-2 (Audit Events)
# -----------------------------------------------------------------------------
# This VPC implements a standard 3-tier architecture:
#   Public subnets  → ALB (internet-facing)
#   Private subnets → Application tier (no direct internet access)
#   (Data tier uses same private subnets with security group isolation)
#
# For FedRAMP, network segmentation is SC-7. The assessor wants to see:
# - Clear public/private separation
# - NACLs as the stateless firewall layer
# - Security groups as the stateful firewall layer (chained: ALB→App→Data)
# - VPC Flow Logs capturing all network traffic
# - No direct SSH access (AC-17) — SSM Session Manager only
# -----------------------------------------------------------------------------

# --- Win 1: VPC + Internet Gateway ---
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-vpc"
    Compliance = "SC-7"
  })
}

# Internet Gateway — the only path between VPC and the internet
# Only public subnets route through this; private subnets are isolated
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

# =============================================================================
# Win 2: PUBLIC SUBNETS — Internet-Facing Tier
# These host ALBs/NLBs only. No application servers go here.
# =============================================================================

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = var.availability_zones[count.index]

  # Public subnets get public IPs for ALB
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  })
}

# Route table: public subnets → Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

# Associate each public subnet with the public route table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# =============================================================================
# Win 3: PRIVATE SUBNETS — Application & Data Tier
# No internet access by default. In production, you'd add a NAT Gateway
# ($0.045/hr = ~$32/mo) for outbound access. We skip it for free tier
# and document it as a "production addition" in the README.
# =============================================================================

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  # Private subnets never get public IPs
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-${var.availability_zones[count.index]}"
    Tier = "private"
  })
}

# Route table: private subnets have NO default route to the internet
# This is the network isolation that FedRAMP requires for app/data tiers
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  # No routes to internet — fully isolated
  # In production: add route to NAT Gateway for outbound-only access

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# =============================================================================
# Win 4: NACLs — Stateless Firewall Layer
# NIST 800-53: SC-7 (Boundary Protection), AC-4 (Information Flow)
# NACLs are the first line of defense — they're stateless (both directions
# need explicit rules) and operate at the subnet level. Security groups
# are the second layer (stateful, resource-level).
# =============================================================================

# --- Public NACL ---
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.public[*].id

  # Allow inbound HTTPS from anywhere (for ALB)
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow inbound HTTP for redirect to HTTPS
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Allow ephemeral ports inbound (return traffic from internet)
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound (ALB needs to reach app tier + internet)
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-public-nacl"
    Compliance = "SC-7 / AC-4"
  })
}

# --- Private NACL ---
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.private[*].id

  # Allow inbound from VPC CIDR only (app traffic from public subnets)
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 65535
  }

  # Allow outbound to VPC CIDR (responses back to public subnets)
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 65535
  }

  # Allow outbound HTTPS for AWS API calls (SSM, CloudWatch, etc.)
  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-private-nacl"
    Compliance = "SC-7 / AC-4"
  })
}

# =============================================================================
# Win 5: SECURITY GROUPS — Stateful Firewall (Tier Chaining)
# NIST 800-53: AC-4 (Information Flow Enforcement)
# This is the "defense in depth" pattern assessors love:
#   Internet → ALB SG (443 only) → App SG (ALB only) → Data SG (App only)
# Each tier can ONLY talk to its adjacent tier. No shortcuts.
# =============================================================================

# --- ALB Security Group ---
# Internet-facing: accepts HTTPS from anywhere, forwards to App tier
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  description = "ALB - allows HTTPS from internet [AC-4]"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-alb-sg"
    Tier       = "public"
    Compliance = "AC-4"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow traffic to App tier only"
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = aws_security_group.app.id
}

# --- App Security Group ---
# Only accepts traffic from ALB, only talks to Data tier
resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-app-"
  description = "App tier - accepts traffic from ALB only [AC-4]"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-app-sg"
    Tier       = "private"
    Compliance = "AC-4"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow traffic from ALB only"
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "app_to_data" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow traffic to Data tier only"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.data.id
}

resource "aws_vpc_security_group_egress_rule" "app_to_https" {
  security_group_id = aws_security_group.app.id
  description       = "Allow HTTPS outbound for AWS API calls"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# --- Data Security Group ---
# Only accepts traffic from App tier. No outbound except responses.
resource "aws_security_group" "data" {
  name_prefix = "${var.project_name}-data-"
  description = "Data tier - accepts traffic from App only [AC-4]"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-data-sg"
    Tier       = "private"
    Compliance = "AC-4"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "data_from_app" {
  security_group_id            = aws_security_group.data.id
  description                  = "Allow PostgreSQL from App tier only"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.app.id
}

# =============================================================================
# Win 6: VPC FLOW LOGS — Network Monitoring
# NIST 800-53: SI-4 (System Monitoring), AU-2 (Audit Events)
# Flow Logs capture ALL network traffic metadata (source, dest, port,
# accept/reject). This is how you detect port scans, lateral movement,
# and data exfiltration attempts. FedRAMP requires network-level logging.
# =============================================================================

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${var.project_name}-flow-logs"
  retention_in_days = 90

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-vpc-flow-logs"
    Compliance = "SI-4 / AU-2"
  })
}

# IAM role for VPC Flow Logs → CloudWatch delivery
resource "aws_iam_role" "flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowFlowLogsAssume"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc-flow-logs-role"
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ]
        Resource = "*"
      }
    ]
  })
}

# The Flow Log itself — captures ALL traffic (accepted + rejected)
resource "aws_flow_log" "this" {
  vpc_id          = aws_vpc.this.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn

  tags = merge(var.common_tags, {
    Name       = "${var.project_name}-vpc-flow-log"
    Compliance = "SI-4 / AU-2"
  })
}
