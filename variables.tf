variable "workload" {
  type    = string
  default = "mic"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "address_space" {
  type    = string
  default = "172.17.0.0/16"
}

variable "postgresql_admin_username" {
  type    = string
  default = "psql"
}

variable "postgresql_admin_password" {
  type      = string
  sensitive = true
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}
