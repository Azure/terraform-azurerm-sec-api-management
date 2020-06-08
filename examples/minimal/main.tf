provider "azurerm" {
  version = "~>2.0"
  features {}
}

module "naming" {
  source = "git::https://github.com/Azure/terraform-azurerm-naming"
}

locals {
  unique_name_stub = substr(module.naming.unique-seed, 0, 5)
}

resource "azurerm_resource_group" "test_group" {
  name     = "${module.naming.resource_group.slug}-${module.naming.api_management.slug}-min-test-${local.unique_name_stub}"
  location = "uksouth"
}

module "apim" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.test_group.name

  # API Management
  apim_publisher_name  = "John Doe"
  apim_publisher_email = "john@doe.com"

  apim_policies_path          = "../../apim_policies/policies.xml"
  enable_authorization_server = false
}
