# EventBridge resources
resource "aws_cloudwatch_event_bus" "example" {
  name              = var.event_source_name
  event_source_name = var.event_source_name
}

resource "aws_cloudwatch_event_rule" "scalr_event_rule" {
  name           = var.rule_name
  event_bus_name = aws_cloudwatch_event_bus.example.event_source_name
  event_pattern = var.event_pattern
}

resource "aws_cloudwatch_event_target" "scalr_event_target" {
  rule           = aws_cloudwatch_event_rule.scalr_event_rule.name
  event_bus_name = aws_cloudwatch_event_bus.example.event_source_name
  target_id      = "lambda-target"
  arn            = var.lambda_function_arn

  retry_policy {
    maximum_retry_attempts = 3
    maximum_event_age_in_seconds = 86400
  }
}

