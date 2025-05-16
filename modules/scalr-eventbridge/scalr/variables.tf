variable "aws_account_id" {
  description = "AWS account ID in which which the trigger events are to be trusted"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "bridge_name" {
  description = "Name of the EventBridge integration"
  type        = string
}
