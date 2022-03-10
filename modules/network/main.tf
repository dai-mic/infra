terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
}

resource "azurerm_virtual_network" "main" {
  name                = azurecaf_name.azurerm_virtual_network.result
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet" "main" {
  name                                           = azurecaf_name.azurerm_subnet.result
  virtual_network_name                           = azurerm_virtual_network.main.name
  resource_group_name                            = azurerm_virtual_network.main.resource_group_name
  address_prefixes                               = [cidrsubnet(var.address_space, 8, 0)]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_network_security_group" "main" {
  name                = azurecaf_name.azurerm_network_security_group.result
  location            = var.location
  resource_group_name = var.resource_group_name

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_subnet" "cluster" {
  name                 = azurecaf_name.azurerm_subnet_cluster.result
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_virtual_network.main.resource_group_name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 1)]
}

resource "azurerm_network_security_group" "cluster" {
  name                = azurecaf_name.azurerm_network_security_group_cluster.result
  location            = var.location
  resource_group_name = var.resource_group_name

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet_network_security_group_association" "cluster" {
  subnet_id                 = azurerm_subnet.cluster.id
  network_security_group_id = azurerm_network_security_group.cluster.id
}

resource "azurerm_subnet" "postgres" {
  name                 = azurecaf_name.azurerm_subnet_postgres.result
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_virtual_network.main.resource_group_name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 2)]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_network_security_group" "postgres" {
  name                = azurecaf_name.azurerm_network_security_group_postgres.result
  location            = var.location
  resource_group_name = var.resource_group_name

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet_network_security_group_association" "postgres" {
  subnet_id                 = azurerm_subnet.postgres.id
  network_security_group_id = azurerm_network_security_group.postgres.id
}

resource "azurerm_subnet" "gateway" {
  name                 = azurecaf_name.azurerm_subnet_gateway.result
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_virtual_network.main.resource_group_name
  address_prefixes     = [cidrsubnet(var.address_space, 8, 3)]
}

resource "azurerm_network_security_group" "gateway" {
  name                = azurecaf_name.azurerm_network_security_group_gateway.result
  location            = var.location
  resource_group_name = var.resource_group_name

  lifecycle {
    ignore_changes = [tags]
  }

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_ranges    = [80, 443]
    direction                  = "Inbound"
    name                       = "AllowInternetIn"
    priority                   = 100
    protocol                   = "TCP"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
  }

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "65200-65535"
    direction                  = "Inbound"
    name                       = "AllowGatewayManagerIn"
    priority                   = 110
    protocol                   = "TCP"
    source_address_prefix      = "GatewayManager"
    source_port_range          = "*"
  }

  security_rule {
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = "*"
    direction                  = "Inbound"
    name                       = "AllowAzureLoadBalancerIn"
    priority                   = 120
    protocol                   = "TCP"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "gateway" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}
