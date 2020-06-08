data "azurerm_client_config" "current" {}

data "azurerm_api_management" "apim" {
  name                = module.apim.api_management.name
  resource_group_name = azurerm_resource_group.test_group.name
}
