terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
}

locals {
  resource_name         = "cr"
  private_dns_zone_name = "privatelink.azurecr.io"
}

resource "azurecaf_name" "azurerm_container_registry" {
  name          = var.workload
  resource_type = "azurerm_container_registry"
  suffixes      = [var.environment, var.location]
}

resource "azurerm_container_registry" "main" {
  name                   = azurecaf_name.azurerm_container_registry.result
  resource_group_name    = var.resource_group_name
  location               = var.location
  sku                    = "Premium"
  admin_enabled          = false
  anonymous_pull_enabled = false

  lifecycle {
    ignore_changes = [tags]
  }
}

module "dns" {
  source              = "../dns"
  name                = local.private_dns_zone_name
  resource_group_name = var.resource_group_name
  environment         = var.environment
  location            = var.location
  resource_name       = local.resource_name
  subresource_name    = "registry"
  resource_id         = azurerm_container_registry.main.id
  subnet_id           = var.private_endpoint_subnet_id
  private_dns_zone_id = var.private_dns_zone_id
}
