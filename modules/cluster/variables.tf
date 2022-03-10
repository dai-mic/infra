variable "workload" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "container_registry_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "application_gateway_id" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.22.4"
}

variable "service_cidr" {
  type    = string
  default = "10.0.0.0/24"
}
