provider "aws" {
  region = var.region
}

module "scalr_event_bridge" {
  source = "./modules/scalr-eventbridge"

  bridge_name = var.bridge_name
  
  # Optional parameters
  s3_bucket_name       = var.s3_bucket_name
  lambda_timeout       = var.lambda_timeout
  lambda_memory        = var.lambda_memory
  log_retention        = var.log_retention
  state_retention_days = var.state_retention_days
}
