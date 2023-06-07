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

  tags = {
    env = "prod"
  }
}

# subnet
resource "azurerm_subnet" "desafio-subnet" {
  name                 = "desafio-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  private_endpoint_network_policies_enabled = true
}

#Network interface
resource "azurerm_network_interface" "desafio_template" {
  count               = var.web_server_count
  name                = "nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "desafio-ipconfig-${count.index}"
    subnet_id                     = azurerm_subnet.desafio-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.webservers-ip[count.index].id
  }
}

# Define the public IP address
resource "azurerm_public_ip" "desafio-publicip" {
  name                = "desafio-publicip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_public_ip" "webservers-ip" {
  count = var.web_server_count
  name                = "webservers-ip-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "Standard"
}

# Define the load balancer
resource "azurerm_lb" "desafio-lb" {
  name                = "desafio-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.desafio-publicip.id
  }
}

# Define the backend pool
resource "azurerm_lb_backend_address_pool" "desafio" {
  name            = "desafio-backendpool"
  loadbalancer_id = azurerm_lb.desafio-lb.id
  depends_on = [ 
    azurerm_public_ip.desafio-publicip
   ]
}

# Define the probe
resource "azurerm_lb_probe" "desafio" {
  name            = "ssh-running-probe"
  loadbalancer_id = azurerm_lb.desafio-lb.id
  protocol        = "Tcp"
  port            = 22
}

resource "azurerm_lb_probe" "desafio1" {
  name            = "probeB"
  loadbalancer_id = azurerm_lb.desafio-lb.id
  port            = 80
}

# Define the load balancer rule
resource "azurerm_lb_rule" "desafio-1" {
  name                           = "desafio-lbrule"
  loadbalancer_id                = azurerm_lb.desafio-lb.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.desafio.id]
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.desafio-lb.frontend_ip_configuration[0].name
  frontend_port                  = 80
  protocol                       = "Tcp"
  probe_id                       = azurerm_lb_probe.desafio1.id
}