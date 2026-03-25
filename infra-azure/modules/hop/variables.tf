variable "environment" {
  type = string
}

variable "aks_cluster_name" {
  description = "Nombre del cluster AKS"
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "acr_login_server" {
  description = "URL del ACR donde está la imagen de Apache Hop"
  type        = string
}

variable "sql_server_fqdn" {
  description = "FQDN del SQL Server"
  type        = string
}

variable "oltp_db_name" {
  description = "Nombre de la BD fuente (OLTP)"
  type        = string
}

variable "reporting_db_name" {
  description = "Nombre de la BD destino (reporting)"
  type        = string
}

variable "storage_account_name" {
  description = "Nombre del Storage Account para reportes"
  type        = string
}

variable "reportes_container_name" {
  description = "Nombre del container de reportes en Blob"
  type        = string
}

variable "hop_schedule" {
  description = "Cron schedule para el ETL (formato K8s CronJob)"
  type        = string
  default     = "0 2 * * *"
}

variable "sql_admin_login" {
  type = string
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}
