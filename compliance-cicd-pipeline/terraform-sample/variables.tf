# -----------------------------------------------------------------------------
# Project-wide variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string
  default     = "fedramp-landing-zone"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "Primary AWS region — restricted to FedRAMP-authorized regions"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-east-2", "us-west-2"], var.aws_region)
    error_message = "Region must be a FedRAMP-authorized region: us-east-1, us-east-2, or us-west-2."
  }
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use (2 minimum for HA)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# -----------------------------------------------------------------------------
# Tagging
# -----------------------------------------------------------------------------

variable "common_tags" {
  description = "Common tags applied to all resources for cost tracking and compliance"
  type        = map(string)
  default = {
    Project     = "fedramp-landing-zone"
    ManagedBy   = "terraform"
    Compliance  = "nist-800-53"
    Environment = "dev"
  }
}
