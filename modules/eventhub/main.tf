terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
}

locals {
  resource_name         = "evhns"
  private_dns_zone_name = "privatelink.servicebus.windows.net"
}

resource "azurecaf_name" "azurerm_eventhub_namespace" {
  name          = var.workload
  resource_type = "azurerm_eventhub_namespace"
  suffixes      = [var.environment, var.location]
}

resource "azurecaf_name" "azurerm_eventhub" {
  name          = var.workload
  resource_type = "azurerm_eventhub"
  suffixes      = [var.environment, var.location]
}

resource "azurerm_eventhub_namespace" "main" {
  name                = azurecaf_name.azurerm_eventhub_namespace.result
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  capacity            = 2
  zone_redundant      = true

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_eventhub" "main" {
  name                = azurecaf_name.azurerm_eventhub.result
  resource_group_name = var.resource_group_name
  namespace_name      = azurerm_eventhub_namespace.main.name
  partition_count     = 2
  message_retention   = 7
}

module "dns" {
  source              = "../dns"
  name                = local.private_dns_zone_name
  resource_group_name = var.resource_group_name
  environment         = var.environment
  location            = var.location
  resource_name       = local.resource_name
  subresource_name    = "namespace"
  resource_id         = azurerm_eventhub_namespace.main.id
  subnet_id           = var.private_endpoint_subnet_id
  private_dns_zone_id = var.private_dns_zone_id
}
