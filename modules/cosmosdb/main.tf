terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
}

locals {
  resource_name         = "cosmos"
  private_dns_zone_name = "privatelink.documents.azure.com"
}

resource "azurecaf_name" "azurerm_cosmosdb_account" {
  name          = var.workload
  resource_type = "azurerm_cosmosdb_account"
  suffixes      = [var.environment, var.location]
}

resource "azurerm_cosmosdb_account" "main" {
  name                            = azurecaf_name.azurerm_cosmosdb_account.result
  location                        = var.location
  resource_group_name             = var.resource_group_name
  offer_type                      = "Standard"
  enable_multiple_write_locations = true
  enable_automatic_failover       = true

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = true
  }

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
  subresource_name    = "Sql"
  resource_id         = azurerm_cosmosdb_account.main.id
  subnet_id           = var.private_endpoint_subnet_id
  private_dns_zone_id = var.private_dns_zone_id
}
