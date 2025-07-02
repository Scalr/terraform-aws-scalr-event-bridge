provider "aws" {
  region = var.region
}

provider "scalr" {
  hostname = "${var.scalr_account_name}.scalr.io"
}

module "scalr_event_bridge" {
  source = "./modules/scalr-eventbridge"

  bridge_name = var.bridge_name

  # Optional parameters
  s3_bucket_name          = var.s3_bucket_name
  s3_force_destroy_bucket = var.s3_force_destroy_bucket
  lambda_timeout          = var.lambda_timeout
  lambda_memory           = var.lambda_memory
  log_retention           = var.log_retention
  state_retention_days    = var.state_retention_days
}
