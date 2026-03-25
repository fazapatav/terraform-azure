output "internal_service_url" {
  description = "URL interna del Service de K8s"
  value       = "svc-api-reportes.${var.kubernetes_namespace}.svc.cluster.local"
}

output "namespace" {
  value = kubernetes_namespace.api.metadata[0].name
}
