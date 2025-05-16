output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = module.s3.kms_key_arn
}

output "service_account_email" {
  description = "Email of the Scalr service account"
  value       = module.scalr.service_account_email
  sensitive   = true
}

output "event_bridge_source_name" {
  description = "Name of the EventBridge integration"
  value       = module.scalr.event_bridge_source_name
}
