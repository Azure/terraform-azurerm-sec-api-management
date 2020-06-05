data "azurerm_resource_group" "base" {
  name = var.resource_group_name
}

data "azurerm_subnet" "subnet" {
  name                 = var.apim_virtual_network_subnet_name
  virtual_network_name = var.apim_virtual_network_name
  resource_group_name  = var.apim_virtual_network_resource_group_name

  count = local.apim_vnet_enabled ? 1 : 0
}
