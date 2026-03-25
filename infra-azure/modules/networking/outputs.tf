output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "subnet_public_id" {
  value = azurerm_subnet.public.id
}

output "subnet_private_id" {
  value = azurerm_subnet.private.id
}

output "subnet_data_id" {
  value = azurerm_subnet.data.id
}

output "subnet_apim_id" {
  value = azurerm_subnet.apim.id
}
