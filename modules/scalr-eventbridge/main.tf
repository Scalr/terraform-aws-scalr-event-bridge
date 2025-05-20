data "aws_caller_identity" "current" {}

module "scalr" {
  source         = "./scalr"
  aws_account_id = data.aws_caller_identity.current.account_id
  bridge_name    = var.bridge_name
}

module "lambda" {
  source = "./lambda"

  s3_bucket_name        = module.s3.bucket_name
  lambda_timeout        = var.lambda_timeout
  lambda_memory         = var.lambda_memory
  log_retention         = var.log_retention
  kms_key_arn           = module.s3.kms_key_arn
  event_bridge_rule_arn = module.eventbridge.rule_arn
  scalr_token           = module.scalr.scalr_token
  scalr_hostname        = module.scalr.scalr_hostname
}

module "eventbridge" {
  source              = "./eventbridge"
  lambda_function_arn = module.lambda.function_arn
  event_pattern = jsonencode({
    source = [
      {
        prefix = "aws.partner/scalr.com"
      }
    ]
    detail-type = ["RunExecuted"]
    detail = {
      event = {
        result = ["applied", "errored"]
        is-dry = [false]
        is-destroy = [false]
      }
    }
  })
  event_source_name = module.scalr.event_bridge_source_name
  rule_name         = "state-backup"
}

module "s3" {
  source = "./s3"

  s3_bucket_name       = var.s3_bucket_name
  state_retention_days = var.state_retention_days
  force_destroy        = var.s3_force_destroy_bucket
}
