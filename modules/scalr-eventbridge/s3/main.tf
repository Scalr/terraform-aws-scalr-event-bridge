# Random string for unique resource names
resource "random_string" "bucket_suffix" {
  length  = 5
  special = false
  upper   = false
}

# KMS key for encryption
resource "aws_kms_key" "lambda_key" {
  description             = "KMS key for Lambda function encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "lambda_key_alias" {
  name          = "alias/scalr-lambda-encryption-key"
  target_key_id = aws_kms_key.lambda_key.key_id
}

# S3 bucket with encryption
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
  }
} 