terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
}

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-rg"
    storage_account_name = "tfstatenaveen12345"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
  }
}


provider "azurerm" {

  subscription_id = "AZURE_SUBSCRIPTION_ID"

  features {}
}

