#Required Variables
variable "resource_group_name" {
  type        = string
  description = "The name of an existing Resource Group to deploy the shared services networking services into."
}

variable "apim_publisher_name" {
  type        = string
  description = "The name of the Azure API Management publisher"
}

variable "apim_publisher_email" {
  type        = string
  description = "The email address of the Azure API Management publisher"
}

#Optional Variables
variable "prefix" {
  type        = list(string)
  description = "A naming prefix to be used in the creation of unique names for Azure resources."
  default     = []
}

variable "suffix" {
  type        = list(string)
  description = "A naming suffix to be used in the creation of unique names for Azure resources."
  default     = []
}

variable "apim_sku" {
  type        = string
  description = "The Azure API Management SKU"
  default     = "Developer_1"
}

variable "apim_virtual_network_type" {
  type        = string
  description = "The virtual network type for the Azure API Management to use (valid: None, Internal, External)"
  default     = "None"
}

variable "apim_virtual_network_name" {
  type        = string
  description = "The virtual network name for the Azure API Management to use"
  default     = ""
}

variable "apim_virtual_network_resource_group_name" {
  type        = string
  description = "The resource group name containing the Azure Virtual Network"
  default     = ""
}

variable "apim_virtual_network_subnet_name" {
  type        = string
  description = "The subnet name to use for the Azure API Management"
  default     = ""
}

variable "apim_policies_path" {
  type        = string
  description = "Path to a file defining the Azure API Management policies in XML"
  default     = ""
}

variable "certificates" {
  type = set(object({
    b64_encoded_certificate = string
    certificate_password    = string
    store_name              = string
  }))
  description = "Client certificates for backend mTLS"
  default     = []
}

variable "enable_authorization_server" {
  type        = bool
  description = "Enable an Authorization Server on Azure API Management"
  default     = true
}

variable "apim_authorization_server_name" {
  type        = string
  description = "The name of the Authorization Server"
  default     = ""
}

variable "apim_authorization_server_display_name" {
  type        = string
  description = "The display name of the Authorization Server"
  default     = ""
}

variable "apim_authorization_server_methods" {
  type        = set(string)
  description = "The HTTP verbs supported by the Authorization Server"
  default     = ["GET"]
}

variable "apim_authorization_server_auth_endpoint" {
  type        = string
  description = "A Authorization Server OAuth2 endpoint"
  default     = ""
}

variable "apim_authorization_server_token_endpoint" {
  type        = string
  description = "A Authorization Server OAuth2 token endpoint"
  default     = ""
}

variable "apim_authorization_server_client_id" {
  type        = string
  description = "A Authorization Server client id"
  default     = ""
}

variable "apim_authorization_server_registration_endpoint" {
  type        = string
  description = "The Authorization Server registration endpoint"
  default     = ""
}

variable "apim_authorization_server_grant_types" {
  type        = set(string)
  description = "Grant types to use with the Authorization Server"
  default     = ["authorizationCode"]
}

variable "apim_bearer_token_sending_methods" {
  type        = set(string)
  description = "The mechanism by which Access Tokens are passed to the API"
  default     = ["authorizationHeader"]
}

variable "apim_identity_type" {
  type        = string
  description = "The type of Managed Service Identity that should be configured"
  default     = ""
}

variable "apim_identity_ids" {
  type        = set(string)
  description = "Set of IDs for User Assigned Managed Identity resources to be assigned"
  default     = []
}

variable "apim_management_host_name" {
  type        = string
  description = "The Hostname to use for the Management API"
  default     = ""
}

variable "apim_management_key_vault_id" {
  type        = string
  description = "The ID of the Azure Key Vault secret containing the certificate"
  default     = ""
}

variable "apim_management_certificate" {
  type        = string
  description = "The Base64 Encoded Certificate"
  default     = ""
}

variable "apim_management_certificate_password" {
  type        = string
  description = "The password associated with the certificate provided above"
  default     = ""
}

variable "apim_management_negotiate_client_certificate" {
  type        = bool
  description = "Should Client Certificate Negotiation be enabled for this Hostname?"
  default     = false
}

variable "apim_portal_host_name" {
  type        = string
  description = "The Hostname to use for the portal API"
  default     = ""
}

variable "apim_portal_key_vault_id" {
  type        = string
  description = "The ID of the Azure Key Vault secret containing the certificate"
  default     = ""
}

variable "apim_portal_certificate" {
  type        = string
  description = "The Base64 Encoded Certificate"
  default     = ""
}

variable "apim_portal_certificate_password" {
  type        = string
  description = "The password associated with the certificate provided above"
  default     = ""
}

variable "apim_portal_negotiate_client_certificate" {
  type        = bool
  description = "Should Client Certificate Negotiation be enabled for this Hostname?"
  default     = false
}

variable "apim_developer_portal_host_name" {
  type        = string
  description = "The Hostname to use for the developer portal API"
  default     = ""
}

variable "apim_developer_portal_certificate" {
  type        = string
  description = "The Base64 Encoded Certificate"
  default     = ""
}

variable "apim_developer_portal_key_vault_id" {
  type        = string
  description = "The ID of the Azure Key Vault secret containing the certificate"
  default     = ""
}

variable "apim_developer_portal_certificate_password" {
  type        = string
  description = "The password associated with the certificate provided above"
  default     = ""
}

variable "apim_developer_portal_negotiate_client_certificate" {
  type        = bool
  description = "Should Client Certificate Negotiation be enabled for this Hostname?"
  default     = false
}

variable "apim_scm_host_name" {
  type        = string
  description = "The Hostname to use for the scm portal API"
  default     = ""
}

variable "apim_scm_key_vault_id" {
  type        = string
  description = "The ID of the Azure Key Vault secret containing the certificate"
  default     = ""
}

variable "apim_scm_certificate" {
  type        = string
  description = "The Base64 Encoded Certificate"
  default     = ""
}

variable "apim_scm_certificate_password" {
  type        = string
  description = "The password associated with the certificate provided above"
  default     = ""
}

variable "apim_scm_negotiate_client_certificate" {
  type        = bool
  description = "Should Client Certificate Negotiation be enabled for this Hostname?"
  default     = false
}

variable "module_depends_on" {
  default = [""]
}

variable "apim_key_vault_name" {
  type        = string
  description = "The name of the source Azure Key Vault"
  default     = ""
}

variable "apim_key_vault_resource_group_name" {
  type        = string
  description = "The name of the resource group containing the source Azure Key Vault"
  default     = ""
}