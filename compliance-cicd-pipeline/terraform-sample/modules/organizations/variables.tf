variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "allowed_regions" {
  description = "List of FedRAMP-authorized AWS regions"
  type        = list(string)
  default     = ["us-east-1", "us-east-2", "us-west-2"]
}
