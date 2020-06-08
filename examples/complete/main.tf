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
  name     = "${module.naming.resource_group.slug}-${module.naming.api_management.slug}-max-test-${local.unique_name_stub}"
  location = "uksouth"
}

resource "azurerm_virtual_network" "test_group" {
  name                = module.naming.virtual_network.name_unique
  location            = azurerm_resource_group.test_group.location
  resource_group_name = azurerm_resource_group.test_group.name
  address_space       = ["10.0.0.0/20"]
}

resource "azurerm_subnet" "test_group" {
  name                                           = "testsubnet"
  resource_group_name                            = azurerm_resource_group.test_group.name
  virtual_network_name                           = azurerm_virtual_network.test_group.name
  address_prefixes                               = [cidrsubnet("10.0.0.0/20", 2, 1)]
  service_endpoints                              = ["Microsoft.KeyVault"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_key_vault" "test_group" {
  name                        = module.naming.key_vault.name_unique
  location                    = azurerm_resource_group.test_group.location
  resource_group_name         = azurerm_resource_group.test_group.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = true
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "set",
      "get"
    ]
  }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "tls_private_key" "test_group" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "test_group" {
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.test_group.private_key_pem

  subject {
    common_name  = "*.example.com"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "azurerm_key_vault_secret" "test_group" {
  name         = "apimcertificate"
  value        = base64encode(tls_self_signed_cert.test_group.cert_pem)
  key_vault_id = azurerm_key_vault.test_group.id
}

# UserAssigned identities cannot be used with Key Vault
# https://feedback.azure.com/forums/248703-api-management/suggestions/38047561-support-for-user-assigned-managed-identity
module "apim" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.test_group.name
  prefix              = [local.unique_name_stub]
  suffix              = [local.unique_name_stub]

  # API Management
  apim_publisher_name  = "John Doe"
  apim_publisher_email = "john@doe.com"
  apim_sku             = "Developer_1"

  ## Virtual Network
  apim_virtual_network_type                = "Internal"
  apim_virtual_network_subnet_name         = azurerm_subnet.test_group.name
  apim_virtual_network_name                = azurerm_virtual_network.test_group.name
  apim_virtual_network_resource_group_name = azurerm_resource_group.test_group.name

  # APIs
  apim_policies_path = "../../apim_policies/policies.xml"
  certificates       = []

  # Authorization
  enable_authorization_server                     = false
  apim_authorization_server_name                  = ""
  apim_authorization_server_display_name          = ""
  apim_authorization_server_auth_endpoint         = ""
  apim_authorization_server_token_endpoint        = ""
  apim_authorization_server_client_id             = ""
  apim_authorization_server_registration_endpoint = ""
  apim_authorization_server_grant_types           = []
  apim_bearer_token_sending_methods               = []
  apim_authorization_server_methods               = []

  apim_identity_type = "SystemAssigned"
  apim_identity_ids  = []
}

resource "azurerm_key_vault_access_policy" "apim" {
  key_vault_id = azurerm_key_vault.test_group.id

  tenant_id = module.apim.api_management.identity[0].tenant_id
  object_id = module.apim.api_management.identity[0].principal_id

  secret_permissions = [
    "get",
  ]
}
