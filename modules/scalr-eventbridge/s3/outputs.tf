output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.states.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.states.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = aws_kms_key.lambda_key.arn
}
