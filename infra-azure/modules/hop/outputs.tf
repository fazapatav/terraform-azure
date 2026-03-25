output "namespace" {
  value = kubernetes_namespace.hop.metadata[0].name
}
