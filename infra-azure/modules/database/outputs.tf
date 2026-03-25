output "sql_server_fqdn" {
  description = "FQDN compartido por ambas BDs"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "oltp_database_name" {
  description = "Nombre de la BD transaccional"
  value       = azurerm_mssql_database.oltp.name
}

output "reporting_database_name" {
  description = "Nombre de la BD espejo para reportes"
  value       = azurerm_mssql_database.reporting.name
}

output "private_endpoint_ip" {
  description = "IP privada del endpoint"
  value       = azurerm_private_endpoint.sql.private_service_connection[0].private_ip_address
}
