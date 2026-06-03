# -----------------------------------------------------------------------------
# Config Rules Module Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for Config delivery"
  type        = string
}

variable "log_bucket_arn" {
  description = "ARN of the S3 bucket for Config delivery"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
