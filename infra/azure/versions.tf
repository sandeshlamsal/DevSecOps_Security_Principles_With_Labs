terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.40" }
  }
  # Local state for a personal lab. For a team: remote state in a storage account with
  # RBAC, versioning and soft delete (state files contain secrets).
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false # never hard-delete keys by accident
    }
  }
}
