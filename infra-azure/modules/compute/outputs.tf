output "aks_cluster_name" {
  description = "Nombre del cluster AKS"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "ID del cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "acr_login_server" {
  description = "URL del registry (ej: acrdev123.azurecr.io)"
  value       = azurerm_container_registry.main.login_server
}

output "kubeconfig" {
  description = "Kubeconfig para conectar kubectl al cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}
