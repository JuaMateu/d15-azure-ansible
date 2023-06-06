terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
                version = "3.53.0"
        }
    }
}

provider "azurerm" {
    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    tenant_id = var.tenant_id
    features {}
}


# resource group "rg" 
resource "azurerm_resource_group" "rg" {
    name     = "educacionit-devops-rg"
    location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "appweb-subnet"
    address_prefix = "10.0.0.0/24"  
    private_endpoint_network_policies_enabled = true
  }

  tags = {
    env = "prod"
  }
}



