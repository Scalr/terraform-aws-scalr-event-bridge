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
