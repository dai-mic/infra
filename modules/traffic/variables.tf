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

variable "endpoints" {
  type = map(object({
    id     = string
    weight = number
  }))
}
