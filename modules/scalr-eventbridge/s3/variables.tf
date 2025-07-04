variable "s3_bucket_name" {
  description = "Name of the S3 bucket for state storage"
  type        = string
  default     = null
}

variable "force_destroy" {
  type    = bool
  default = false
  description = "Whether to force destroy the bucket during destruction of infrastructure"
}

variable "state_retention_days" {
  description = "Number of days to retain state files in S3"
  type        = number
  default     = 90
}

variable "noncurrent_version_retention_days" {
  description = "Number of days to retain noncurrent versions of state files"
  type        = number
  default     = 30
}

variable "access_log_retention_days" {
  description = "Number of days to retain access logs"
  type        = number
  default     = 30
} 