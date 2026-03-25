variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_apim_id" {
  description = "ID de la subred dedicada para APIM"
  type        = string
}

variable "publisher_name" {
  type    = string
  default = "Fintech Corp"
}

variable "publisher_email" {
  type    = string
  default = "admin@fintech.co"
}

variable "api_service_url" {
  description = "URL interna del Service K8s de la API .NET"
  type        = string
}

variable "openid_config_url" {
  description = "URL de configuración OpenID para validar JWT"
  type        = string
  default     = ""
}
