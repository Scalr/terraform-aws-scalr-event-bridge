variable "bus_name" {
  type = string
  description = "The created event bus name."
}

variable "workspace_names" {
  type = list(string)
  description = "The list of whitelisted workspaces."
}

variable "environment_names" {
  type = list(string)
  description = "The list of whitelisted environments"
}

variable "tags" {
  type = list(string)
  description = "The list of of tags assigned to workspaces to trigger runs in."
}
