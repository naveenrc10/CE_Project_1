terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
}

provider "azurerm" {
  tenant_id       = ""
  subscription_id = ""
  client_id       = ""
  client_secret   = ""
  features {}
}

