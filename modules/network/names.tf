resource "azurecaf_name" "azurerm_virtual_network" {
  name          = var.workload
  resource_type = "azurerm_virtual_network"
  suffixes      = [var.environment, var.location]
}

resource "azurecaf_name" "azurerm_subnet" {
  name          = var.workload
  resource_type = "azurerm_subnet"
  suffixes      = [var.environment, var.location]
}

resource "azurecaf_name" "azurerm_subnet_cluster" {
  name          = var.workload
  resource_type = "azurerm_subnet"
  suffixes      = ["aks", var.environment, var.location]
}

resource "azurecaf_name" "azurerm_subnet_gateway" {
  name          = var.workload
  resource_type = "azurerm_subnet"
  suffixes      = ["agw", var.environment, var.location]
}

resource "azurecaf_name" "azurerm_subnet_postgres" {
  name          = var.workload
  resource_type = "azurerm_subnet"
  suffixes      = ["sql", var.environment, var.location]
}

resource "azurecaf_name" "azurerm_network_security_group" {
  name          = var.workload
  resource_type = "azurerm_network_security_group"
  suffixes      = [var.environment, var.location]
}

resource "azurecaf_name" "azurerm_network_security_group_cluster" {
  name          = var.workload
  resource_type = "azurerm_network_security_group"
  suffixes      = ["aks", var.environment, var.location]
}

resource "azurecaf_name" "azurerm_network_security_group_gateway" {
  name          = var.workload
  resource_type = "azurerm_network_security_group"
  suffixes      = ["agw", var.environment, var.location]
}

resource "azurecaf_name" "azurerm_network_security_group_postgres" {
  name          = var.workload
  resource_type = "azurerm_network_security_group"
  suffixes      = ["sql", var.environment, var.location]
}