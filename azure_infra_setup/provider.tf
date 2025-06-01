terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
}

provider "azurerm" {
  tenant_id       = "AZURE_TENANT_ID"
  subscription_id = ""
  client_id       = "AZURE_APP_ID"
  client_secret   = "AZURE_PASSWORD"
  features {}
}

