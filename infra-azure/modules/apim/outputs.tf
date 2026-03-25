output "apim_gateway_url" {
  description = "URL del gateway de APIM"
  value       = azurerm_api_management.main.gateway_url
}

output "apim_name" {
  value = azurerm_api_management.main.name
}
