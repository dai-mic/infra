resource "azurecaf_name" "azurerm_public_ip" {
  name          = var.workload
  resource_type = "azurerm_public_ip"
  suffixes      = [var.environment, var.location]
}

resource "azurecaf_name" "azurerm_kubernetes_cluster" {
  name          = var.workload
  resource_type = "azurerm_kubernetes_cluster"
  suffixes      = [var.environment, var.location]
}

resource "azurecaf_name" "azurerm_role_assignment" {
  name          = var.workload
  resource_type = "azurerm_role_assignment"
  suffixes      = [var.environment, var.location]
}
