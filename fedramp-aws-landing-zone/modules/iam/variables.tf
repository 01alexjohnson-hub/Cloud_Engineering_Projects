# -----------------------------------------------------------------------------
# IAM Module Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "allowed_regions" {
  description = "FedRAMP-authorized regions for permission boundary"
  type        = list(string)
  default     = ["us-east-1", "us-east-2", "us-west-2"]
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
