data "azurerm_api_management" "apim" {
  name                = module.apim.apim_name
  resource_group_name = azurerm_resource_group.test_group.name
}
