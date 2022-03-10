terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
}

data "azurerm_client_config" "main" {
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

locals {
  virtual_network_name = split("/", var.subnet_id)[8]
  virtual_network_id   = join("/", slice(split("/", var.subnet_id), 0, 9))
  azure_defender_cli = jsonencode({
    location = "${var.location}"
    properties = {
      securityProfile = {
        azureDefender = {
          enabled                         = true,
          logAnalyticsWorkspaceResourceId = "${var.log_analytics_workspace_id}"
        }
      }
    }
  })
}

resource "azurerm_public_ip" "main" {
  name                = azurecaf_name.azurerm_public_ip.result
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  sku_tier            = "Regional"
  allocation_method   = "Static"
  domain_name_label   = "${var.workload}-${var.environment}"

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_kubernetes_cluster" "main" {
  name                      = azurecaf_name.azurerm_kubernetes_cluster.result
  resource_group_name       = var.resource_group_name
  location                  = var.location
  dns_prefix                = var.workload
  automatic_channel_upgrade = "node-image"
  kubernetes_version        = var.kubernetes_version
  local_account_disabled    = true
  azure_policy_enabled      = true

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                         = "system"
    vm_size                      = "Standard_DS3_v2"
    availability_zones           = [1, 2, 3]
    enable_auto_scaling          = true
    only_critical_addons_enabled = true
    os_disk_size_gb              = 30
    os_disk_type                 = "Ephemeral"
    os_sku                       = "Ubuntu"
    vnet_subnet_id               = var.subnet_id
    max_count                    = 3
    min_count                    = 1

    upgrade_settings {
      max_surge = "100%"
    }
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  ingress_application_gateway {
    gateway_id = var.application_gateway_id
  }

  maintenance_window {
    allowed {
      day   = "Saturday"
      hours = range(1, 5)
    }

    allowed {
      day   = "Sunday"
      hours = range(1, 5)
    }
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    dns_service_ip     = cidrhost(var.service_cidr, 10)
    docker_bridge_cidr = "192.168.0.1/24"
    service_cidr       = var.service_cidr

    load_balancer_profile {
      outbound_ip_address_ids  = [azurerm_public_ip.main.id]
      outbound_ports_allocated = 4096
    }
  }

  role_based_access_control {
    enabled = true
    azure_active_directory {
      azure_rbac_enabled = true
      managed            = true
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "main" {
  name                  = "default"
  vm_size               = "Standard_F4s_v2"
  availability_zones    = [1, 2, 3]
  enable_auto_scaling   = true
  os_disk_size_gb       = 30
  os_disk_type          = "Ephemeral"
  os_sku                = "Ubuntu"
  vnet_subnet_id        = var.subnet_id
  max_count             = 3
  min_count             = 1
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  node_taints           = ["tier=stable:NoSchedule"]

  upgrade_settings {
    max_surge = "100%"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "beta" {
  name                  = "beta"
  vm_size               = "Standard_F4s_v2"
  availability_zones    = [1, 2, 3]
  enable_auto_scaling   = true
  os_disk_size_gb       = 30
  os_disk_type          = "Ephemeral"
  os_sku                = "Ubuntu"
  vnet_subnet_id        = var.subnet_id
  max_count             = 3
  min_count             = 1
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id

  node_labels = {
    tier = "beta"
  }

  upgrade_settings {
    max_surge = "100%"
  }
}

resource "azurerm_resource_policy_assignment" "cluster" {
  name                 = "k8s pod security baseline standards for Linux-based workloads"
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d"
  resource_id          = azurerm_kubernetes_cluster.main.id
  parameters           = <<PARAMETERS
  {
    "effect": {
      "value": "deny"
    }
  }
  PARAMETERS
}

resource "azurerm_role_assignment" "aks_rbac_cluster_admin" {
  principal_id         = data.azurerm_client_config.main.object_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.main.id
}

resource "azurerm_role_assignment" "kubelet_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity.0.object_id
  role_definition_name = "AcrPull"
  scope                = var.container_registry_id
}

resource "azurerm_role_assignment" "aks" {
  for_each = {
    "Network Contributor" = var.subnet_id
  }
  scope                = each.value
  role_definition_name = each.key
  principal_id         = azurerm_kubernetes_cluster.main.identity.0.principal_id
}

resource "azurerm_role_assignment" "agw" {
  for_each = {
    "Contributor" = var.application_gateway_id
    "Reader"      = data.azurerm_resource_group.main.id
  }
  scope                = each.value
  role_definition_name = each.key
  principal_id         = azurerm_kubernetes_cluster.main.addon_profile[0].ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

resource "null_resource" "azure_defender" {
  depends_on = [
    azurerm_kubernetes_cluster.main
  ]

  provisioner "local-exec" {
    command = "az rest -m put -u ${data.azurerm_resource_group.main.id}/providers/Microsoft.ContainerService/managedClusters/${azurerm_kubernetes_cluster.main.name}?api-version=2021-07-01 -b ${local.azure_defender_cli}"
  }
}
