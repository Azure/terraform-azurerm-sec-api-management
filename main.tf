provider "azurerm" {
  version = "~>2.18"
  features {}
}

locals {
  apim_vnet_type        = var.apim_virtual_network_type
  apim_vnet_enabled     = local.apim_vnet_type != "None"
  apim_identity_enabled = var.apim_identity_type != ""
}

module "naming" {
  source = "git::https://github.com/Azure/terraform-azurerm-naming"
  suffix = var.suffix
  prefix = var.prefix
}

# UserAssigned identities are currently in preview but don't seem to be working
# yet for accessing key vault secrets/certificates. We therefore, only define
# hostname configuration if you're using a APIM certificate directly rather 
# than an Azure Key Vault certificate. If you are using an Azure Key Vault
# certificate then the honstame configuration will be applied after the
# SystemAssigned MSI has been given access to the Azure Key Vault.
# Related issues:
# - https://github.com/terraform-providers/terraform-provider-azurerm/issues/3058
# - https://github.com/terraform-providers/terraform-provider-azurerm/issues/3635
# - https://feedback.azure.com/forums/248703-api-management/suggestions/38047561-support-for-user-assigned-managed-identity
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
}

resource "azurerm_key_vault_access_policy" "apim" {
  key_vault_id = data.azurerm_key_vault.keyvault[0].id

  tenant_id = azurerm_api_management.apim.identity[0].tenant_id
  object_id = azurerm_api_management.apim.identity[0].principal_id

  secret_permissions = [
    "get",
  ]

  count = var.apim_key_vault_enabled ? 1 : 0
}

# TODO: Remove once UserAssigned MSI work with APIM + KeyVault
resource "null_resource" "apim" {
  depends_on = [
    azurerm_key_vault_access_policy.apim,
    azurerm_api_management.apim
  ]

  triggers = {
    apim_name                         = azurerm_api_management.apim.name
    apim_rg_name                      = azurerm_api_management.apim.resource_group_name
    apim_mgmt_host                    = var.apim_management_host_name
    apim_mgmt_kv_id                   = var.apim_management_key_vault_id
    apim_mgmt_client_cert             = var.apim_management_negotiate_client_certificate
    apim_portal_host                  = var.apim_portal_host_name
    apim_portal_kv_id                 = var.apim_portal_key_vault_id
    apim_portal_client_cert           = var.apim_portal_negotiate_client_certificate
    apim_developer_portal_host        = var.apim_developer_portal_host_name
    apim_developer_portal_kv_id       = var.apim_developer_portal_key_vault_id
    apim_developer_portal_client_cert = var.apim_developer_portal_negotiate_client_certificate
    apim_scm_host                     = var.apim_scm_host_name
    apim_scm_kv_id                    = var.apim_scm_key_vault_id
    apim_scm_client_cert              = var.apim_scm_negotiate_client_certificate
  }

  provisioner "local-exec" {
    command = format("%s/scripts/host_config.sh %s %s %s %s %s %s %s %s %s %s %s %s %s %s",
      path.module,
      azurerm_api_management.apim.name,
      azurerm_api_management.apim.resource_group_name,
      var.apim_management_host_name,
      var.apim_management_key_vault_id,
      var.apim_management_negotiate_client_certificate,
      var.apim_portal_host_name,
      var.apim_portal_key_vault_id,
      var.apim_portal_negotiate_client_certificate,
      var.apim_developer_portal_host_name,
      var.apim_developer_portal_key_vault_id,
      var.apim_developer_portal_negotiate_client_certificate,
      var.apim_scm_host_name,
      var.apim_scm_key_vault_id,
      var.apim_scm_negotiate_client_certificate
    )
  }

  count = var.apim_key_vault_enabled ? 1 : 0
}

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
