# IAM role and policy
resource "aws_iam_role" "lambda_role" {
  name = "scalr-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "random_string" "api_token" {
  length  = 5
  special = false
}

# Secrets Manager secret for Scalr token
resource "aws_secretsmanager_secret" "scalr_token" {
  name                    = "scalr-api-token-${random_string.api_token.result}"
  description             = "Scalr API token for EventBridge integration"
  recovery_window_in_days = 7
  kms_key_id              = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "scalr_token" {
  secret_id = aws_secretsmanager_secret.scalr_token.id
  secret_string = jsonencode({
    token = var.scalr_token
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "scalr-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/scalr-state-processor:*"
      },
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect   = "Allow"
        Resource = var.kms_key_arn
      },
      {
        Action = [
          "sqs:SendMessage"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.lambda_dlq.arn
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.scalr_token.arn
      }
    ]
  })
}

# Dead Letter Queue for Lambda
resource "aws_sqs_queue" "lambda_dlq" {
  name = "scalr-lambda-dlq"
  message_retention_seconds = 1209600 # 14 days

  kms_master_key_id = var.kms_key_arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "process_event_lambda" {
  filename                       = data.archive_file.lambda_zip.output_path
  function_name                  = "scalr-state-processor"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "lambda_function.lambda_handler"
  runtime                        = "python3.11"
  timeout                        = var.lambda_timeout
  memory_size                    = var.lambda_memory
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  reserved_concurrent_executions = var.lambda_reserved_concurrency

  environment {
    variables = {
      SCALR_HOSTNAME   = var.scalr_hostname
      AWS_BUCKET       = var.s3_bucket_name
      SCALR_SECRET_ARN = aws_secretsmanager_secret.scalr_token.arn
    }
  }

  kms_key_arn = var.kms_key_arn

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  tracing_config {
    mode = "Active"
  }

  # Ensure IAM role and policy are fully created before Lambda function
  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_sqs_queue.lambda_dlq
  ]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/scalr-state-processor"
  retention_in_days = var.log_retention
  kms_key_id        = var.kms_key_arn
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "scalr-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors lambda function errors"
  actions_enabled     = true

  dimensions = {
    FunctionName = "scalr-state-processor"
  }

  depends_on = [aws_lambda_function.process_event_lambda]
}


resource "aws_lambda_permission" "allow_event_bridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_event_lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = var.event_bridge_rule_arn
}