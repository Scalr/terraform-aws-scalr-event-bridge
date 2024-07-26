provider "aws" {
  region = "us-east-1"
}

data "aws_iam_policy_document" "trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Effect   = "Allow",
        Resource = aws_cloudwatch_log_group.process_event_log_group.arn,
      }
    ],
  })
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_event_lambda.arn
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.scalr_event_rule.arn
}


resource "aws_lambda_function" "process_event_lambda" {
  filename         = "lambda_function_payload.zip"
  function_name    = "ProcessEventLambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  environment {
    variables = {
      SCALR_HOSTNAME = regex("^[^@]+@(.+)$", scalr_service_account.event_bridge.email)[0]
      SCALR_TOKEN    = scalr_service_account_token.default.token
      SCALR_TAGS     = join(",", var.tags)
    }
  }
}

resource "aws_cloudwatch_log_group" "process_event_log_group" {
  name              = "/aws/lambda/ProcessEventLambda"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_rule" "scalr_event_rule" {
  name           = "run-executed"
  event_bus_name = var.bus_name
  event_pattern  = jsonencode({
    "source": [{
      "prefix": "aws.partner/scalr.com"
    }],
    "detail-type": ["RunExecuted"],
    "detail": {
      "event": {
        "workspace": var.workspace_names,
        "environment": var.environment_names,
        "result": ["applied"],
        "is-destroy": [false]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "scalr_event_target" {
  rule           = aws_cloudwatch_event_rule.scalr_event_rule.name
  event_bus_name = var.bus_name
  target_id      = "lambda-target"
  arn            = aws_lambda_function.process_event_lambda.arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.process_event_lambda.arn
}