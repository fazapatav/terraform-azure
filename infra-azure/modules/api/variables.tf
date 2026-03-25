variable "environment" {
  type = string
}

variable "kubernetes_namespace" {
  type    = string
  default = "fintech-api"
}

variable "acr_login_server" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "sql_server_fqdn" {
  type = string
}

variable "reporting_db_name" {
  type = string
}

variable "sql_admin_login" {
  type = string
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

variable "aks_cluster_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}
