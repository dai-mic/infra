terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
}

resource "azurecaf_name" "azurerm_traffic_manager_profile" {
  name          = var.workload
  resource_type = "azurerm_traffic_manager_profile"
  suffixes      = [var.environment, var.location]
}

resource "azurerm_traffic_manager_profile" "main" {
  name                   = azurecaf_name.azurerm_traffic_manager_profile.result
  resource_group_name    = var.resource_group_name
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = "${var.workload}-${var.environment}"
    ttl           = 60
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    expected_status_code_ranges  = ["200-299"]
    interval_in_seconds          = 30
    timeout_in_seconds           = 5
    tolerated_number_of_failures = 1
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "main" {
  for_each           = var.endpoints
  name               = each.key
  profile_id         = azurerm_traffic_manager_profile.main.id
  target_resource_id = each.value.id
  weight             = each.value.weight
}
