#!/bin/bash

# This is a temporary script required to enable API Management
# to set the host configuraiton using Azure Key Vault references
# whilst there is not support for UserAssigned Manage Service
# Identities for Key Vault Access in the Terraform Provider.

set -e

APIM_SVC_NAME=${1}
APIM_RESOURCE_GROUP_NAME=${2}

MGMT_HOST_NAME=${3}
MGMT_KEY_VAULT_ID=${4}
MGMT_NEGOTIATE_CLIENT_CERT=${5}

PORTAL_HOST_NAME=${6}
PORTAL_KEY_VAULT_ID=${7}
PORTAL_NEGOTIATE_CLIENT_CERT=${8}

DEVELOPER_PORTAL_HOST_NAME=${9}
DEVELOPER_PORTAL_KEY_VAULT_ID=${10}
DEVELOPER_PORTAL_NEGOTIATE_CLIENT_CERT=${11}

SCM_HOST_NAME=${12}
SCM_KEY_VAULT_ID=${13}
SCM_NEGOTIATE_CLIENT_CERT=${14}

if [ -z ${APIM_SVC_NAME} ] || [ -z ${APIM_RESOURCE_GROUP_NAME} ]; then
    echo "APIM_SVC_NAME and APIM_RESOURCE_GROUP_NAME args are required!"
    exit 1
fi

CURR_CONFIG=$(az apim show -n ${APIM_SVC_NAME} -g ${APIM_RESOURCE_GROUP_NAME} --query 'hostnameConfigurations')

if ! [ -z ${MGMT_HOST_NAME} ] && [ ${MGMT_KEY_VAULT_ID} != "-" ]; then
    echo "Set management host configuration"
    MGMT_CONFIG="[{\"type\":\"Management\",\"hostName\":\"${MGMT_HOST_NAME}\",\"keyVaultId\":\"${MGMT_KEY_VAULT_ID}\",\"negotiateClientCertificate\":${MGMT_NEGOTIATE_CLIENT_CERT}, \"defaultSslBinding\": false}]"
    # MGMT_CONFIG takes precedence over existing values on conflict
    CURR_CONFIG=$(jq --argjson arr1 "$CURR_CONFIG" --argjson arr2 "$MGMT_CONFIG" -n '$arr2 + $arr1 | unique_by(.type)')
fi

if ! [ -z ${PORTAL_HOST_NAME} ] && [ ${PORTAL_KEY_VAULT_ID} != "-" ]; then
    echo "Set portal host configuration"
    PORTAL_CONFIG="[{\"type\":\"Portal\",\"hostName\":\"${PORTAL_HOST_NAME}\",\"keyVaultId\":\"${PORTAL_KEY_VAULT_ID}\",\"negotiateClientCertificate\":${PORTAL_NEGOTIATE_CLIENT_CERT}, \"defaultSslBinding\": false}]"
    # PORTAL_CONFIG takes precedence over existing values on conflict
    CURR_CONFIG=$(jq --argjson arr1 "$CURR_CONFIG" --argjson arr2 "$PORTAL_CONFIG" -n '$arr2 + $arr1 | unique_by(.type)')
fi

if ! [ -z ${DEVELOPER_PORTAL_HOST_NAME} ] && [ ${DEVELOPER_PORTAL_KEY_VAULT_ID} != "-" ]; then
    echo "Set developer portal host configuration"
    DEVELOPER_PORTAL_CONFIG="[{\"type\":\"DeveloperPortal\",\"hostName\":\"${DEVELOPER_PORTAL_HOST_NAME}\",\"keyVaultId\":\"${DEVELOPER_PORTAL_KEY_VAULT_ID}\",\"negotiateClientCertificate\":${DEVELOPER_PORTAL_NEGOTIATE_CLIENT_CERT}, \"defaultSslBinding\": false}]"
    # DEVELOPER_PORTAL_CONFIG takes precedence over existing values on conflict
    CURR_CONFIG=$(jq --argjson arr1 "$CURR_CONFIG" --argjson arr2 "$DEVELOPER_PORTAL_CONFIG" -n '$arr2 + $arr1 | unique_by(.type)')
fi

if ! [ -z ${SCM_HOST_NAME} ] && [ ${SCM_KEY_VAULT_ID} != "-" ]; then
    echo "Set scm host configuration"
    SCM_CONFIG="[{\"type\":\"Scm\",\"hostName\":\"${SCM_HOST_NAME}\",\"keyVaultId\":\"${SCM_KEY_VAULT_ID}\",\"negotiateClientCertificate\":${SCM_NEGOTIATE_CLIENT_CERT}, \"defaultSslBinding\": false}]"
    # SCM_CONFIG takes precedence over existing values on conflict
    CURR_CONFIG=$(jq --argjson arr1 "$CURR_CONFIG" --argjson arr2 "$SCM_CONFIG" -n '$arr2 + $arr1 | unique_by(.type)')
fi

CURR_CONFIG=$(echo "${CURR_CONFIG}" | jq -c .)
az apim update -g ${APIM_RESOURCE_GROUP_NAME} -n ${APIM_SVC_NAME} --set hostnameConfigurations="${CURR_CONFIG}"
echo "Set host configuration"

