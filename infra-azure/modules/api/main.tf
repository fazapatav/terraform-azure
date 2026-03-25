data "azurerm_kubernetes_cluster" "main" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

provider "kubernetes" {
  alias                  = "api"
  host                   = data.azurerm_kubernetes_cluster.main.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.main.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.main.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate)
}

# ── Namespace para la API ────────────────────────────────────
resource "kubernetes_namespace" "api" {
  metadata {
    name = var.kubernetes_namespace
    labels = {
      environment = var.environment
      app         = "api-reportes"
    }
  }
}

# ── Secret con credenciales para la API ──────────────────────
resource "kubernetes_secret" "api_secrets" {
  metadata {
    name      = "api-reportes-secrets"
    namespace = kubernetes_namespace.api.metadata[0].name
  }

  data = {
    BLOB_CONNECTION_STRING = "DefaultEndpointsProtocol=https;AccountName=${var.storage_account_name};EndpointSuffix=core.windows.net"
    SQL_REPORTING_CONN     = "Server=${var.sql_server_fqdn};Database=${var.reporting_db_name};User Id=${var.sql_admin_login};Password=${var.sql_admin_password};Encrypt=true;"
  }

  type = "Opaque"
}

# ── Deployment de la API .NET ─────────────────────────────────
resource "kubernetes_deployment_v1" "dotnet_api" {
  metadata {
    name      = "api-reportes"
    namespace = kubernetes_namespace.api.metadata[0].name
    labels = {
      app         = "api-reportes"
      environment = var.environment
    }
  }

  spec {
    replicas = var.environment == "prod" ? 3 : 1

    selector {
      match_labels = { app = "api-reportes" }
    }

    template {
      metadata {
        labels = { app = "api-reportes" }
      }

      spec {
        node_selector = { agentpool = "user" }

        container {
          name  = "api-reportes"
          image = "${var.acr_login_server}/api-reportes:latest"

          port { container_port = 8080 }

          env {
            name = "BLOB_CONNECTION_STRING"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.api_secrets.metadata[0].name
                key  = "BLOB_CONNECTION_STRING"
              }
            }
          }

          env {
            name = "SQL_REPORTING_CONN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.api_secrets.metadata[0].name
                key  = "SQL_REPORTING_CONN"
              }
            }
          }

          env {
            name  = "ASPNETCORE_ENVIRONMENT"
            value = var.environment == "prod" ? "Production" : "Development"
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }

          readiness_probe {
            http_get {
              path = "/health/ready"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# ── Service interno — APIM se conecta aquí ────────────────────
resource "kubernetes_service_v1" "dotnet_api" {
  metadata {
    name      = "svc-api-reportes"
    namespace = kubernetes_namespace.api.metadata[0].name
    annotations = {
      "service.beta.kubernetes.io/azure-load-balancer-internal" = "true"
    }
  }

  spec {
    selector = { app = "api-reportes" }
    type     = "ClusterIP"

    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }
}
