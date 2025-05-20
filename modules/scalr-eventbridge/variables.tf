variable "bridge_name" {
  description = "Name of the EventBridge integration"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for state storage"
  type        = string
  default     = null
}

variable "s3_force_destroy_bucket" {
  description = "Name of the S3 bucket for state storage"
  type        = bool
  default     = false
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 256
}

variable "log_retention" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "state_retention_days" {
  description = "Number of days to retain state files in S3"
  type        = number
  default     = 90
} 