output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.scalr_event_bridge.lambda_function_arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.scalr_event_bridge.s3_bucket_name
}

output "service_account_email" {
  description = "Email of the Scalr service account"
  value = module.scalr_event_bridge.service_account_email
}