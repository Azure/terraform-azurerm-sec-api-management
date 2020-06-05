provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "null_resource" "module_depends_on" {
  triggers = {
    value = "${length(var.module_depends_on)}"
  }
}

locals {
  apim_vnet_type        = var.apim_virtual_network_type
  apim_vnet_enabled     = local.apim_vnet_type != "None"
  apim_identity_enabled = var.apim_identity_type != ""
  apim_management_enabled = length(
    format("%s%s%s%s",
      var.apim_management_host_name,
      var.apim_management_key_vault_id,
      var.apim_management_certificate,
  var.apim_management_certificate_password)) > 0
  apim_portal_enabled = length(
    format("%s%s%s%s",
      var.apim_portal_host_name,
      var.apim_portal_key_vault_id,
      var.apim_portal_certificate,
  var.apim_portal_certificate_password)) > 0
  apim_developer_portal_enabled = length(
    format("%s%s%s%s",
      var.apim_developer_portal_host_name,
      var.apim_developer_portal_key_vault_id,
      var.apim_developer_portal_certificate,
  var.apim_developer_portal_certificate_password)) > 0
  apim_scm_enabled = length(
    format("%s%s%s%s",
      var.apim_scm_host_name,
      var.apim_scm_key_vault_id,
      var.apim_scm_certificate,
  var.apim_scm_certificate_password)) > 0
  hostname_configuration_enabled = local.apim_management_enabled || local.apim_developer_portal_enabled || local.apim_portal_enabled || local.apim_scm_enabled
}

module "naming" {
  source = "git@github.com:Azure/terraform-azurerm-naming"
  suffix = var.suffix
  prefix = var.prefix
}

resource "azurerm_api_management" "apim" {
  name                = module.naming.api_management.name_unique
  location            = data.azurerm_resource_group.base.location
  resource_group_name = data.azurerm_resource_group.base.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email

  sku_name = var.apim_sku

  virtual_network_type = local.apim_vnet_type

  dynamic "virtual_network_configuration" {
    for_each = local.apim_vnet_enabled ? [1] : []

    content {
      subnet_id = data.azurerm_subnet.subnet[0].id
    }
  }

  dynamic "certificate" {
    for_each = var.certificates

    content {
      encoded_certificate  = certificate.value.b64_encoded_certificate
      certificate_password = certificate.value.certificate_password
      store_name           = certificate.value.store_name
    }
  }

  dynamic "identity" {
    for_each = local.apim_identity_enabled ? [1] : []

    content {
      type         = var.apim_identity_type
      identity_ids = length(var.apim_identity_ids) > 0 ? var.apim_identity_ids : null
    }
  }

  policy {
    xml_content = file(var.apim_policies_path)
  }

  dynamic "hostname_configuration" {
    for_each = local.hostname_configuration_enabled ? [1] : []

    content {
      dynamic "management" {
        for_each = local.apim_management_enabled ? [1] : []

        content {
          host_name                    = length(var.apim_management_host_name) > 0 ? var.apim_management_host_name : null
          key_vault_id                 = length(var.apim_management_key_vault_id) > 0 ? var.apim_management_key_vault_id : null
          certificate                  = length(var.apim_management_certificate) > 0 ? var.apim_management_certificate : null
          certificate_password         = length(var.apim_management_certificate_password) > 0 ? var.apim_management_certificate_password : null
          negotiate_client_certificate = var.apim_management_negotiate_client_certificate
        }
      }

      dynamic "portal" {
        for_each = local.apim_portal_enabled ? [1] : []

        content {
          host_name                    = length(var.apim_portal_host_name) > 0 ? var.apim_portal_host_name : null
          key_vault_id                 = length(var.apim_portal_key_vault_id) > 0 ? var.apim_portal_key_vault_id : null
          certificate                  = length(var.apim_portal_certificate) > 0 ? var.apim_portal_certificate : null
          certificate_password         = length(var.apim_portal_certificate_password) > 0 ? var.apim_portal_certificate_password : null
          negotiate_client_certificate = var.apim_portal_negotiate_client_certificate
        }
      }

      dynamic "developer_portal" {
        for_each = local.apim_developer_portal_enabled ? [1] : []

        content {
          host_name                    = length(var.apim_developer_portal_host_name) > 0 ? var.apim_developer_portal_host_name : null
          key_vault_id                 = length(var.apim_developer_portal_key_vault_id) > 0 ? var.apim_developer_portal_key_vault_id : null
          certificate                  = length(var.apim_developer_portal_certificate) > 0 ? var.apim_developer_portal_certificate : null
          certificate_password         = length(var.apim_developer_portal_certificate_password) > 0 ? var.apim_developer_portal_certificate_password : null
          negotiate_client_certificate = var.apim_developer_portal_negotiate_client_certificate
        }
      }

      dynamic "scm" {
        for_each = local.apim_scm_enabled ? [1] : []

        content {
          host_name                    = length(var.apim_scm_host_name) > 0 ? var.apim_scm_host_name : null
          key_vault_id                 = length(var.apim_scm_key_vault_id) > 0 ? var.apim_scm_key_vault_id : null
          certificate                  = length(var.apim_scm_certificate) > 0 ? var.apim_scm_certificate : null
          certificate_password         = length(var.apim_scm_certificate_password) > 0 ? var.apim_scm_certificate_password : null
          negotiate_client_certificate = var.apim_scm_negotiate_client_certificate
        }
      }
    }
  }

  depends_on = [null_resource.module_depends_on]
}

# TODO: Do we need this or does diagnostics work ok?
# resource "azurerm_api_management_logger" "apim" {
#   name                = var.apim_logger_name
#   api_management_name = azurerm_api_management.apim.name
#   resource_group_name = data.azurerm_resource_group.base.name

#   application_insights {
#     instrumentation_key = azurerm_application_insights.example.instrumentation_key
#   }
# }

# resource "azurerm_api_management_diagnostic" "apim" {
#   identifier               = "loganalytics"
#   resource_group_name      = azurerm_resource_group.example.name
#   api_management_name      = azurerm_api_management.example.name
#   api_management_logger_id = azurerm_api_management_logger.example.id
# }

resource "azurerm_api_management_authorization_server" "apim" {
  name                         = var.apim_authorization_server_name
  api_management_name          = azurerm_api_management.apim.name
  authorization_methods        = var.apim_authorization_server_methods
  resource_group_name          = data.azurerm_resource_group.base.name
  display_name                 = var.apim_authorization_server_display_name
  authorization_endpoint       = var.apim_authorization_server_auth_endpoint
  token_endpoint               = var.apim_authorization_server_token_endpoint
  bearer_token_sending_methods = var.apim_bearer_token_sending_methods
  client_id                    = var.apim_authorization_server_client_id
  client_registration_endpoint = var.apim_authorization_server_registration_endpoint

  grant_types = var.apim_authorization_server_grant_types

  count = var.enable_authorization_server ? 1 : 0
}
