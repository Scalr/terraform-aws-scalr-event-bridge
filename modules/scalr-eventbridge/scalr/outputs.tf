output "scalr_token" {
  description = "The token to authenticate lambda functions"
  value = scalr_service_account_token.default.token
  sensitive = true
}

output "scalr_hostname" {
  value = replace(scalr_service_account.event_bridge.email, "${scalr_service_account.event_bridge.name}@", "")
}

output "event_bridge_source_name" {
  value = scalr_event_bridge_integration.example.event_source_name
}

output "service_account_email" {
  value = scalr_service_account.event_bridge.email
}
