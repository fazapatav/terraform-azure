variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_private_id" {
  type        = string
  description = "ID de la subred privada — para el Private Endpoint"
}

variable "vnet_id" {
  type        = string
  description = "ID de la VNet — para enlazar la Private DNS Zone"
}

variable "sql_admin_login" {
  type    = string
  default = "sqladmin"
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

variable "sku_oltp" {
  description = "Tier para la BD transaccional"
  type        = string
  default     = "GP_Gen5_4"
}

variable "sku_reporting" {
  description = "Tier para la BD de reportes"
  type        = string
  default     = "GP_S_Gen5_2"
}

variable "max_size_gb_oltp" {
  type    = number
  default = 128
}

variable "max_size_gb_reporting" {
  type    = number
  default = 256
}
