variable "event_source_name" {
  description = "The event bridge source name."
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to invoke"
  type        = string
}

variable "rule_name" {
  description = "Name of the EventBridge Rule to invoke"
  type        = string
}

variable "event_pattern" {
  type = string
  description = "The event severity text to invoke"
}