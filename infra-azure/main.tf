module "networking" {
  source                = "./modules/networking"
  environment           = var.environment
  location              = var.location
  vnet_address_space    = var.vnet_address_space
  subnet_public_prefix  = var.subnet_public_prefix
  subnet_private_prefix = var.subnet_private_prefix
  subnet_data_prefix    = var.subnet_data_prefix
  subnet_apim_prefix    = var.subnet_apim_prefix
}

module "compute" {
  source              = "./modules/compute"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  subnet_private_id   = module.networking.subnet_private_id
  node_count          = var.node_count
  node_min_count      = var.node_min_count
  node_max_count      = var.node_max_count
  node_vm_size        = var.node_vm_size
}

module "database" {
  source                = "./modules/database"
  environment           = var.environment
  location              = var.location
  resource_group_name   = module.networking.resource_group_name
  subnet_private_id     = module.networking.subnet_private_id
  vnet_id               = module.networking.vnet_id
  sql_admin_login       = var.sql_admin_login
  sql_admin_password    = var.sql_admin_password
  sku_oltp              = var.sku_oltp
  sku_reporting         = var.sku_reporting
  max_size_gb_oltp      = var.max_size_gb_oltp
  max_size_gb_reporting = var.max_size_gb_reporting
}

module "storage" {
  source              = "./modules/storage"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  subnet_private_id   = module.networking.subnet_private_id
  vnet_id             = module.networking.vnet_id
}

module "hop" {
  source              = "./modules/hop"
  environment         = var.environment
  resource_group_name = module.networking.resource_group_name
  aks_cluster_name    = module.compute.aks_cluster_name
  acr_login_server    = module.compute.acr_login_server
  sql_server_fqdn     = module.database.sql_server_fqdn
  oltp_db_name        = module.database.oltp_database_name
  reporting_db_name   = module.database.reporting_database_name
  storage_account_name    = module.storage.storage_account_name
  reportes_container_name = module.storage.reportes_container_name
  hop_schedule        = var.hop_schedule
  sql_admin_login     = var.sql_admin_login
  sql_admin_password  = var.sql_admin_password
}

module "api" {
  source               = "./modules/api"
  environment          = var.environment
  kubernetes_namespace = "fintech-api"
  acr_login_server     = module.compute.acr_login_server
  storage_account_name = module.storage.storage_account_name
  sql_server_fqdn      = module.database.sql_server_fqdn
  reporting_db_name    = module.database.reporting_database_name
  sql_admin_login      = var.sql_admin_login
  sql_admin_password   = var.sql_admin_password
  aks_cluster_name     = module.compute.aks_cluster_name
  resource_group_name  = module.networking.resource_group_name
}

module "apim" {
  source              = "./modules/apim"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.networking.resource_group_name
  subnet_apim_id      = module.networking.subnet_apim_id
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  api_service_url     = module.api.internal_service_url
  openid_config_url   = var.openid_config_url
}
