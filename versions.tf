terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    scalr = {
      source = "scalr/scalr"
      version = "~> 1.12"
    }
  }
}
