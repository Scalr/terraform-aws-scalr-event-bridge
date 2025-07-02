output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.process_event_lambda.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.process_event_lambda.function_name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}

output "dlq_arn" {
  description = "ARN of the Dead Letter Queue"
  value       = aws_sqs_queue.lambda_dlq.arn
}

output "scalr_secret_arn" {
  description = "ARN of the Scalr token secret in Secrets Manager"
  value       = aws_secretsmanager_secret.scalr_token.arn
}
