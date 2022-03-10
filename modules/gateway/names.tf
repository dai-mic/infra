resource "azurecaf_name" "azurerm_public_ip" {
  name          = var.workload
  resource_type = "azurerm_public_ip"
  suffixes      = ["agw", var.environment, var.location]
}

resource "azurecaf_name" "azurerm_web_application_firewall_policy" {
  name          = var.workload
  resource_type = "azurerm_web_application_firewall_policy"
  suffixes      = [var.environment, var.location]
}

resource "azurecaf_name" "azurerm_application_gateway" {
  name          = var.workload
  resource_type = "azurerm_application_gateway"
  suffixes      = [var.environment, var.location]
}
