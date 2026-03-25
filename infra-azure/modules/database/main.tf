resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ══════════════════════════════════════════════════════════════
# SQL SERVER — un solo server lógico aloja ambas bases de datos
# ══════════════════════════════════════════════════════════════
resource "azurerm_mssql_server" "main" {
  name                          = "sql-${var.environment}-${random_string.suffix.result}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = var.sql_admin_password
  public_network_access_enabled = false
  minimum_tls_version           = "1.2"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ══════════════════════════════════════════════════════════════
# BASE DE DATOS 1 — OLTP (transaccional)
# ══════════════════════════════════════════════════════════════
resource "azurerm_mssql_database" "oltp" {
  name                        = "sqldb-oltp-${var.environment}"
  server_id                   = azurerm_mssql_server.main.id
  sku_name                    = var.sku_oltp
  auto_pause_delay_in_minutes = -1
  max_size_gb                 = var.max_size_gb_oltp
  zone_redundant              = var.environment == "prod" ? true : false

  short_term_retention_policy {
    retention_days           = var.environment == "prod" ? 35 : 7
    backup_interval_in_hours = 12
  }

  long_term_retention_policy {
    weekly_retention  = var.environment == "prod" ? "P4W" : "PT0S"
    monthly_retention = var.environment == "prod" ? "P12M" : "PT0S"
    yearly_retention  = var.environment == "prod" ? "P5Y" : "PT0S"
    week_of_year      = 1
  }

  tags = {
    environment = var.environment
    purpose     = "transactional"
    managed_by  = "terraform"
  }
}

# ══════════════════════════════════════════════════════════════
# BASE DE DATOS 2 — REPORTING (espejo para reportes)
# Apache Hop escribe aquí, los generadores de reportes leen aquí
# ══════════════════════════════════════════════════════════════
resource "azurerm_mssql_database" "reporting" {
  name                        = "sqldb-reporting-${var.environment}"
  server_id                   = azurerm_mssql_server.main.id
  sku_name                    = var.sku_reporting
  auto_pause_delay_in_minutes = var.environment == "prod" ? 120 : 60
  max_size_gb                 = var.max_size_gb_reporting
  collation                   = "SQL_Latin1_General_CP1_CI_AS"

  short_term_retention_policy {
    retention_days           = 7
    backup_interval_in_hours = 24
  }

  tags = {
    environment = var.environment
    purpose     = "reporting"
    managed_by  = "terraform"
  }
}

# ══════════════════════════════════════════════════════════════
# PRIVATE ENDPOINT — un solo endpoint para el SQL Server
# Ambas BDs accesibles por la misma IP privada
# ══════════════════════════════════════════════════════════════
resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_private_id

  private_service_connection {
    name                           = "psc-sql-${var.environment}"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-sql-${var.environment}"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ── Private DNS Zone ──────────────────────────────────────────
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "dns-link-sql-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

# ── Auditoría ─────────────────────────────────────────────────
resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  server_id              = azurerm_mssql_server.main.id
  log_monitoring_enabled = true
  retention_in_days      = var.environment == "prod" ? 90 : 7
}
