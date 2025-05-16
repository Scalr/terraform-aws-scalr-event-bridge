# Scalr service account and integration
data "scalr_current_account" "account" {}

data "scalr_role" "read_only" {
  name = "read-only"
}

resource "scalr_service_account" "event_bridge" {
  name        = "event-bridge"
  description = "Used for Scalr & AWS Event Bridge Integration"
  status      = "Active"
}

resource "scalr_event_bridge_integration" "example" {
  name           = var.bridge_name
  aws_account_id = var.aws_account_id
  region         = var.aws_region
}

resource "scalr_service_account_token" "default" {
  service_account_id = scalr_service_account.event_bridge.id
  description        = "Created by Terraform"
}


# Access policy for service account
resource "scalr_access_policy" "service_account_access" {
  subject {
    type = "service_account"
    id   = scalr_service_account.event_bridge.id
  }

  scope {
    type = "account"
    id   = data.scalr_current_account.account.id
  }

  role_ids = [
    data.scalr_role.read_only.id
  ]
}
