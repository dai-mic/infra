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

variable "subnet_id" {
  type = string
}

variable "admin_username" {
  type    = string
  default = null
}

variable "admin_password" {
  type      = string
  sensitive = true
  default   = null
}

variable "source_server_id" {
  type    = string
  default = null
}

variable "private_dns_zone_id" {
  type = string
}

variable "private_endpoint_subnet_id" {
  type = string
}
