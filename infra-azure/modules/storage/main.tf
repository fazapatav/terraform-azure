resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ── Storage Account ───────────────────────────────────────────
resource "azurerm_storage_account" "main" {
  name                            = "st${var.environment}${random_string.suffix.result}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.environment == "prod" ? "ZRS" : "LRS"
  account_kind                    = "StorageV2"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = var.environment == "prod" ? 30 : 7
    }
    versioning_enabled = var.environment == "prod" ? true : false
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ── Container: reportes (Apache Hop deposita .avro.snappy.p7z) ─
resource "azurerm_storage_container" "reportes" {
  name                  = "reportes"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# ── Container: metadata (estado de cada envío) ────────────────
resource "azurerm_storage_container" "metadata" {
  name                  = "metadata"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# ── Lifecycle policy — mover reportes viejos a tier frío ──────
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "archive-old-reports"
    enabled = true

    filters {
      prefix_match = ["reportes/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 90
        tier_to_archive_after_days_since_modification_greater_than = 365
      }
    }
  }
}

# ── Private Endpoint para Blob Storage ───────────────────────
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-storage-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_private_id

  private_service_connection {
    name                           = "psc-storage-${var.environment}"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-storage-${var.environment}"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }
}

resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "dns-link-storage-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}
