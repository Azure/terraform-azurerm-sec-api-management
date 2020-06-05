provider "azurerm" {
  version = "~>2.0"
  features {}
}

module "naming" {
  source = "git@github.com:Azure/terraform-azurerm-naming"
}

resource "azurerm_resource_group" "test_group" {
  name     = "${module.naming.resource_group.slug}-${module.naming.api_management.slug}-min-test-${substr(module.naming.unique-seed, 0, 5)}"
  location = "uksouth"
}

module "apim" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.test_group.name

  # API Management
  apim_publisher_name  = "John Doe"
  apim_publisher_email = "john@doe.com"
  apim_sku             = "Developer_1"

  apim_policies_path          = "../../policies.xml"
  enable_authorization_server = false
}
