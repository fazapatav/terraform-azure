variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "chilecentral"
}

# ── Networking ────────────────────────────────────────────────
variable "vnet_address_space" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_public_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_private_prefix" {
  type    = string
  default = "10.0.2.0/24"
}

variable "subnet_data_prefix" {
  type    = string
  default = "10.0.3.0/24"
}

variable "subnet_apim_prefix" {
  type    = string
  default = "10.0.4.0/27"
}

# ── Compute (AKS) ────────────────────────────────────────────
variable "node_count" {
  type    = number
  default = 1
}

variable "node_min_count" {
  type    = number
  default = 1
}

variable "node_max_count" {
  type    = number
  default = 3
}

variable "node_vm_size" {
  type    = string
  default = "Standard_B2s"
}

# ── Database ──────────────────────────────────────────────────
variable "sql_admin_login" {
  type    = string
  default = "sqladmin"
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

variable "sku_oltp" {
  type    = string
  default = "GP_S_Gen5_1"
}

variable "sku_reporting" {
  type    = string
  default = "GP_S_Gen5_1"
}

variable "max_size_gb_oltp" {
  type    = number
  default = 4
}

variable "max_size_gb_reporting" {
  type    = number
  default = 4
}

# ── Hop ETL ───────────────────────────────────────────────────
variable "hop_schedule" {
  type    = string
  default = "0 2 * * *"
}

# ── APIM ──────────────────────────────────────────────────────
variable "publisher_name" {
  type    = string
  default = "Fintech Corp"
}

variable "publisher_email" {
  type    = string
  default = "admin@fintech.co"
}

variable "openid_config_url" {
  type    = string
  default = ""
}
