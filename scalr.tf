data "scalr_role" "user" {
  name = "user"
}

resource "scalr_service_account" "event_bridge" {
  name        = "event-bridge"
  description = "Used for Scalr & AWS Event Bridge Integration"
  status      = "Active"
}

resource "scalr_service_account_token" "default" {
  service_account_id = scalr_service_account.event_bridge.id
  description        = "Created by Tofu"
}

data "scalr_current_account" "account" {}

resource "scalr_access_policy" "team_read_all_on_acc_scope" {
  subject {
    type = "service_account"
    id   = scalr_service_account.event_bridge.id
  }

  scope {
    type = "account"
    id   = data.scalr_current_account.account.id
  }

  role_ids = [
    data.scalr_role.user.id
  ]
}