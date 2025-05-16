variable "s3_bucket_name" {
  description = "Name of the S3 bucket for state storage"
  type        = string
  default     = null
}

variable "state_retention_days" {
  description = "Number of days to retain state files in S3"
  type        = number
  default     = 90
} 