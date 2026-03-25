output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "storage_account_id" {
  value = azurerm_storage_account.main.id
}

output "reportes_container_name" {
  value = azurerm_storage_container.reportes.name
}

output "metadata_container_name" {
  value = azurerm_storage_container.metadata.name
}

output "primary_blob_endpoint" {
  description = "Endpoint privado — usado en connection strings"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}
