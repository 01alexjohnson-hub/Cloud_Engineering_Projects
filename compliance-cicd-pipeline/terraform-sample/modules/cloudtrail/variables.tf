# -----------------------------------------------------------------------------
# CloudTrail Module Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail log delivery"
  type        = string
}

variable "log_bucket_policy_dependency" {
  description = "Dependency hook to ensure bucket policy exists before trail creation"
  type        = any
  default     = null
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
