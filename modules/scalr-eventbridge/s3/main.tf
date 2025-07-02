# Random string for unique resource names
resource "random_string" "bucket_suffix" {
  length  = 5
  special = false
  upper   = false
}

# KMS key for encryption with explicit policy
resource "aws_kms_key" "lambda_key" {
  description             = "KMS key for Lambda function encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda Service"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow SQS Service"
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "lambda_key_alias" {
  name          = "alias/scalr-lambda-encryption-key"
  target_key_id = aws_kms_key.lambda_key.key_id
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# S3 bucket for access logs
resource "aws_s3_bucket" "access_logs" {
  bucket        = "${var.s3_bucket_name != null ? var.s3_bucket_name : "scalr-states-backup-${random_string.bucket_suffix.result}"}-access-logs"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs_encryption" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.lambda_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs_pab" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning for access logs bucket
resource "aws_s3_bucket_versioning" "access_logs_versioning" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle configuration for access logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "access_logs_lifecycle" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "cleanup-old-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.access_log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Main S3 bucket with enhanced security
resource "aws_s3_bucket" "states" {
  bucket = var.s3_bucket_name != null ? var.s3_bucket_name : "scalr-states-backup-${random_string.bucket_suffix.result}"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_server_side_encryption_configuration" "states_encryption" {
  bucket = aws_s3_bucket.states.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.lambda_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Public Access Block
resource "aws_s3_bucket_public_access_block" "states_pab" {
  bucket = aws_s3_bucket.states.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "states_versioning" {
  bucket = aws_s3_bucket.states.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Access Logging
resource "aws_s3_bucket_logging" "states_logging" {
  bucket = aws_s3_bucket.states.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "access-logs/"
}

# Enhanced Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "states_lifecycle" {
  bucket = aws_s3_bucket.states.id

  rule {
    id     = "cleanup-old-states"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.state_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
} 