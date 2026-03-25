# ── Container Registry (ACR) ──────────────────────────────────
# AKS necesita de dónde jalar las imágenes Docker.
resource "azurerm_container_registry" "main" {
  name                = "acr${var.environment}${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ── Log Analytics — observabilidad del cluster ────────────────
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-aks-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ── Cluster AKS ───────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.environment}"
  kubernetes_version  = "1.29"

  # ── System node pool (obligatorio) ──────────────────────────
  default_node_pool {
    name                         = "system"
    node_count                   = var.node_count
    vm_size                      = var.node_vm_size
    vnet_subnet_id               = var.subnet_private_id
    enable_auto_scaling          = true
    min_count                    = var.node_min_count
    max_count                    = var.node_max_count
    os_disk_size_gb              = 50
    os_disk_type                 = "Managed"
    only_critical_addons_enabled = true
  }

  # ── Identidad administrada ───────────────────────────────────
  identity {
    type = "SystemAssigned"
  }

  # ── Red — Azure CNI ──────────────────────────────────────────
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  # ── RBAC con Azure AD ────────────────────────────────────────
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  # ── Monitoreo ────────────────────────────────────────────────
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ── User node pool — aquí corren tus workloads ────────────────
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.node_vm_size
  vnet_subnet_id        = var.subnet_private_id
  enable_auto_scaling   = true
  min_count             = var.node_min_count
  max_count             = var.node_max_count
  node_count            = var.node_count
  os_disk_size_gb       = 50

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ── Permiso para que AKS jale imágenes del ACR ───────────────
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}
