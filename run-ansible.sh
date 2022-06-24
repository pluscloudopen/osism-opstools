#!/bin/bash

##############################################################################################
#
# This wrapper sets up SSH key for Ansible and OS_* env vars for openstack-cli / opentacksdk
#
# Requires the following env vars to be set:
# - VAULT_ADDR
# - VAULT_TOKEN
# - REGION_NAME
#
##############################################################################################

set -ueo pipefail

TODO: Copy this script to run-ansible.sh.local and edit PATHs as required

VAULT_SSH_PATH=openstack/${REGION_NAME}/dragon_id_rsa
VAULT_ADMINRC_PATH=secret/plusserver/openstack/manage-openstack/${REGION_NAME}

echo "Downloading SSH key from vault:${VAULT_SSH_PATH} into /tmp/id_rsa"
vault read  -field data $VAULT_SSH_PATH > /tmp/id_rsa
chmod 600 /tmp/id_rsa

echo "Setting up Openstack admin credentials for environment $REGION_NAME"
vault read  -field env $VAULT_ADMINRC_PATH > /tmp/admin.rc
set -a ; . /tmp/admin.rc ; set +a

"$@"


