data "azurerm_resource_group" "base" {
  name = var.resource_group_name
}

data "azurerm_subnet" "subnet" {
  name                 = var.apim_virtual_network_subnet_name
  virtual_network_name = var.apim_virtual_network_name
  resource_group_name  = var.apim_virtual_network_resource_group_name

  count = local.apim_vnet_enabled ? 1 : 0
}

data "azurerm_key_vault" "keyvault" {
  name                = var.apim_key_vault_name
  resource_group_name = var.apim_key_vault_resource_group_name

  count = var.apim_key_vault_enabled ? 1 : 0
}