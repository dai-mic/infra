terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.98.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.15"
    }
  }

  backend "azurerm" {
    use_azuread_auth = true
    key              = "mic"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "3ffd12a6-2c31-4875-89ef-1372bb937c74"
}

provider "azurecaf" {
}

locals {
  private_dns_zones = {
    cosmosdb = "privatelink.documents.azure.com",
    eventhub = "privatelink.servicebus.windows.net",
    postgres = "privatelink.postgres.database.azure.com",
    registry = "privatelink.azurecr.io",
  }
}

data "azurerm_client_config" "current" {
}

resource "azurecaf_name" "resource_group" {
  name          = var.workload
  resource_type = "azurerm_resource_group"
  suffixes      = [var.environment, var.location]
}

resource "azurerm_resource_group" "main" {
  name     = azurecaf_name.resource_group.result
  location = var.location

  tags = {
    workload    = var.workload
    environment = var.environment
    location    = var.location
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_private_dns_zone" "main" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.main.name

  lifecycle {
    ignore_changes = [tags]
  }
}

module "network" {
  source              = "./modules/network"
  workload            = var.workload
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.address_space
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each              = local.private_dns_zones
  name                  = each.value
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = each.value
  virtual_network_id    = module.network.id

  lifecycle {
    ignore_changes = [tags]
  }
}

module "monitor" {
  source              = "./modules/monitor"
  workload            = var.workload
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

module "postgresql" {
  source                     = "./modules/postgresql"
  workload                   = var.workload
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  subnet_id                  = module.network.postgres_subnet_id
  private_endpoint_subnet_id = module.network.subnet_id
  admin_username             = var.postgresql_admin_username
  admin_password             = var.postgresql_admin_password
  private_dns_zone_id        = azurerm_private_dns_zone.main["postgres"].id
}

module "cosmosdb" {
  source                     = "./modules/cosmosdb"
  workload                   = var.workload
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  private_endpoint_subnet_id = module.network.subnet_id
  private_dns_zone_id        = azurerm_private_dns_zone.main["cosmosdb"].id
}

module "registry" {
  source                     = "./modules/registry"
  workload                   = var.workload
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  private_endpoint_subnet_id = module.network.subnet_id
  private_dns_zone_id        = azurerm_private_dns_zone.main["registry"].id
}

module "eventhub" {
  source                     = "./modules/eventhub"
  workload                   = var.workload
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  private_endpoint_subnet_id = module.network.subnet_id
  private_dns_zone_id        = azurerm_private_dns_zone.main["eventhub"].id
}

module "cluster" {
  source                     = "./modules/cluster"
  workload                   = var.workload
  environment                = var.environment
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = module.monitor.id
  container_registry_id      = module.registry.id
  subnet_id                  = module.network.cluster_subnet_id
  application_gateway_id     = module.gateway.id
}

module "gateway" {
  source              = "./modules/gateway"
  workload            = var.workload
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.network.gateway_subnet_id
}

# module "traffic" {
#   source              = "./modules/traffic"
#   workload            = var.workload
#   environment         = var.environment
#   location            = var.location
#   resource_group_name = azurerm_resource_group.main.name
#   endpoints           = { default = { id = module.cluster.public_ip_id, weight = 1000 } }
# }

resource "null_resource" "az_cli_aks" {
  depends_on = [
    module.cluster
  ]

  provisioner "local-exec" {
    command = <<EOF
      az account set -s ${var.subscription_id}
      az aks get-credentials -n ${module.cluster.name} -g ${azurerm_resource_group.main.name} --context ${var.workload}-${var.environment} --overwrite-existing -o none
      kubelogin convert-kubeconfig -l azurecli
    EOF
    interpreter = [
      "powershell"
    ]
  }
}
