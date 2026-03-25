# ── Proveedor Kubernetes apuntando al AKS ya creado ──────────
data "azurerm_kubernetes_cluster" "main" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.main.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.main.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.main.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate)
}

# ── Namespace dedicado para los workloads ETL ────────────────
resource "kubernetes_namespace" "hop" {
  metadata {
    name = "etl-hop"
    labels = {
      environment = var.environment
      app         = "apache-hop"
    }
  }
}

# ── Secret con las connection strings de ambas BDs ───────────
resource "kubernetes_secret" "sql_credentials" {
  metadata {
    name      = "sql-credentials"
    namespace = kubernetes_namespace.hop.metadata[0].name
  }

  data = {
    OLTP_JDBC_URL      = "jdbc:sqlserver://${var.sql_server_fqdn}:1433;database=${var.oltp_db_name};encrypt=true;trustServerCertificate=false"
    REPORTING_JDBC_URL = "jdbc:sqlserver://${var.sql_server_fqdn}:1433;database=${var.reporting_db_name};encrypt=true;trustServerCertificate=false"
    SQL_USER           = var.sql_admin_login
    SQL_PASSWORD       = var.sql_admin_password
  }

  type = "Opaque"
}

# ── ConfigMap con la configuración de Hop ────────────────────
resource "kubernetes_config_map" "hop_config" {
  metadata {
    name      = "hop-config"
    namespace = kubernetes_namespace.hop.metadata[0].name
  }

  data = {
    HOP_LOG_LEVEL      = var.environment == "prod" ? "Basic" : "Debug"
    HOP_MAX_LOG_LINES  = "5000"
    PIPELINE_PATH      = "/opt/hop/pipelines"
    STORAGE_ACCOUNT    = var.storage_account_name
    REPORTES_CONTAINER = var.reportes_container_name
  }
}

# ── CronJob — ejecuta el ETL en horario programado ───────────
resource "kubernetes_cron_job_v1" "hop_etl" {
  metadata {
    name      = "hop-etl-pipeline"
    namespace = kubernetes_namespace.hop.metadata[0].name
    labels = {
      app         = "apache-hop"
      component   = "etl"
      environment = var.environment
    }
  }

  spec {
    schedule                      = var.hop_schedule
    concurrency_policy            = "Forbid"
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 3

    job_template {
      metadata {}
      spec {
        backoff_limit = 2

        template {
          metadata {}
          spec {
            restart_policy = "OnFailure"

            node_selector = {
              agentpool = "user"
            }

            container {
              name  = "hop-runner"
              image = "${var.acr_login_server}/apache-hop:2.9.0"

              command = [
                "/bin/bash", "-c",
                "hop-run.sh -r local -j /opt/hop/pipelines/fintech-etl.hwf -l $(HOP_LOG_LEVEL)"
              ]

              env_from {
                secret_ref {
                  name = kubernetes_secret.sql_credentials.metadata[0].name
                }
              }

              env_from {
                config_map_ref {
                  name = kubernetes_config_map.hop_config.metadata[0].name
                }
              }

              resources {
                requests = {
                  cpu    = "500m"
                  memory = "1Gi"
                }
                limits = {
                  cpu    = "2000m"
                  memory = "4Gi"
                }
              }
            }
          }
        }
      }
    }
  }
}
