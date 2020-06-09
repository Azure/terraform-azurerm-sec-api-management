provider "azurerm" {
  version = "~>2.13.0"
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
      "get",
      "delete"
    ]

    certificate_permissions = [
      "create",
      "get",
      "getissuers",
      "setissuers",
      "update",
      "delete"
    ]

    key_permissions = [
      "create",
      "decrypt",
      "encrypt",
      "import",
      "sign",
      "update",
      "verify",
    ]
  }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_certificate" "test_group" {
  name         = "generated-cert"
  key_vault_id = azurerm_key_vault.test_group.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = [
          "dev.example.com",
          "mgmt.example.com",
          "scm.example.com",
        "portal.example.com"]
      }

      subject            = "CN=*.example.com"
      validity_in_months = 12
    }
  }
}

module "apim" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.test_group.name
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

  apim_key_vault_enabled             = true # This can not be dynamically resolved due to: https://github.com/hashicorp/terraform/issues/21634
  apim_key_vault_name                = azurerm_key_vault.test_group.name
  apim_key_vault_resource_group_name = azurerm_resource_group.test_group.name

  # Management
  apim_management_host_name                    = "mgmt.example.com"
  apim_management_key_vault_id                 = azurerm_key_vault_certificate.test_group.secret_id
  apim_management_negotiate_client_certificate = false

  # Portal
  apim_portal_host_name                    = "portal.example.com"
  apim_portal_key_vault_id                 = azurerm_key_vault_certificate.test_group.secret_id
  apim_portal_negotiate_client_certificate = false

  # Dev Portal
  apim_developer_portal_host_name                    = "dev.example.com"
  apim_developer_portal_key_vault_id                 = azurerm_key_vault_certificate.test_group.secret_id
  apim_developer_portal_negotiate_client_certificate = false

  # SCM
  apim_scm_host_name                    = "scm.example.com"
  apim_scm_key_vault_id                 = azurerm_key_vault_certificate.test_group.secret_id
  apim_scm_negotiate_client_certificate = false

  module_depends_on = []
}
