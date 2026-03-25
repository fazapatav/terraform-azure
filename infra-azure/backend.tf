terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatefintech"
    container_name       = "tfstate"
    key                  = "dev.networking.tfstate"
  }
}
