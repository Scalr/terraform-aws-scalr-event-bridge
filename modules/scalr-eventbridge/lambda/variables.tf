variable "scalr_hostname" {
  description = "Scalr hostname for API access"
  type        = string
}


variable "scalr_token" {
  description = "Scalr API token"
  type        = string
  sensitive   = true
}

variable "event_bridge_rule_arn" {
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for state storage"
  type        = string
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

variable "lambda_reserved_concurrency" {
  description = "Lambda function reserved concurrency limit"
  type        = number
  default     = 10
}

variable "log_retention" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  type        = string
}
