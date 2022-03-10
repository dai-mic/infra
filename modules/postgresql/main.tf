terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
}

locals {
  resource_name         = "psql"
  private_dns_zone_name = "privatelink.postgres.database.azure.com"
}

resource "azurecaf_name" "azurerm_postgresql_flexible_server" {
  name          = var.workload
  resource_type = "azurerm_postgresql_flexible_server"
  suffixes      = [var.environment, var.location]
}

resource "azurecaf_name" "azurerm_postgresql_flexible_server_database" {
  name          = var.workload
  resource_type = "azurerm_postgresql_flexible_server_database"
  suffixes      = [var.environment, var.location]
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = azurecaf_name.azurerm_postgresql_flexible_server.result
  location               = var.location
  resource_group_name    = var.resource_group_name
  administrator_login    = var.admin_username
  administrator_password = var.admin_password

  backup_retention_days        = 30
  geo_redundant_backup_enabled = true
  create_mode                  = "Default"
  delegated_subnet_id          = var.subnet_id
  private_dns_zone_id          = var.private_dns_zone_id

  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = 2
  }

  maintenance_window {
    day_of_week  = 0
    start_hour   = 0
    start_minute = 0
  }

  sku_name   = "GP_Standard_D2s_v3"
  storage_mb = 32768
  version    = 13
  zone       = 1

  lifecycle {
    ignore_changes = [zone, tags, high_availability.0.standby_availability_zone]
  }
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = azurecaf_name.azurerm_postgresql_flexible_server_database.result
  server_id = azurerm_postgresql_flexible_server.main.id
}
