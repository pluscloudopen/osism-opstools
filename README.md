# OSISM opstools

Collection Ansible playbooks for operational tasks across multiple Openstack installations.
They are intended to run from within a Docker container on either local notebook or on a central
management host like Jenkins or so.

Currently implemented playbooks:

- compute node restarts (still beta)
- acpi module activation
- Check for correctness of metadata agents across all compute nodes

## Requirements

### Docker container

Create a container with the required tool stack.

```bash
docker build -t osism-opstools .
```

### Openstack account with administrative rights

``` bash
openstack user create --description "osism-opstools admin" --domain default \
    --project service --password .......... --email ..........  osism-opstools-admin

openstack role add --user osism-opstools-admin --project service admin
```

### Other Openstack resources

```bash
opestack project create service
openstack network create --project service service-testing
openstack subnet create --project service --network service-testing  --subnet-range 192.168.42.0/24 service-testing-subnet

# You may  want to use dragon's key. This will not upload the private key rather than create a pub-key and upload that
openstack keypair create --user -osism-opstools-admin --private-key /tmp/ssh_id --type ssh service-testing-dragon
```

### Create /tmp/admin.rc file and upload to Vault

Example /tmp/admin.rc:

```bash
OS_AUTH_URL=https://keystone-url:5000/v3
OS_DOMAIN_NAME=default
OS_PROJECT_NAME=service
OS_USERNAME=osism-opstools-admin
OS_PASSWORD=xxxxxxxxxxxx
```

Upload to Vault:

```bash
cat /tmp/admin.rc |  vault write openstack/manage-openstack/some_region env=-
```

### Upload dragon SSH private key to Vault

- get operators key from Ansible-Vault (ansible-vault view OSISM_CONFIG_REPO/region/environments/secrets.yml)
- store it to /tmp/id_rsa

```bash
cat /tmp/id_rsa |  vault write openstack/dev2.api.pco.get-cloud.io/dragon_id_rsa data=-
```

## Usage

### Configure environment

Setup environment to operate on the desired region

```bash
> osism.env
echo VAULT_TOKEN=$(cat $HOME/.vault-token) >> osism.env
echo REGION_NAME=someregion  >> osism.env
```

Note:

- VAULT_TOKEN is needed for the container to download SSH-Key and admin.rc file.
- REGION_NAME is the target region and used to compute VAULT's lookup path and determine inventory file

Create a handy docker-run shortcut:

```bash
alias osism-opstool-cmd="docker run -it --rm --env-file osism.env -v $(pwd):/workspace -w /workspace  --entrypoint=/workspace/run-ansible.sh.local osism-opstools"
```


### Run then playbook

#### compute restart

The following code will restart compute1 in $REGION_NAME:

```bash
osism-opstools-cmd ansible-playbook -i inventories/$REGION_NAME restart-compute.yml -l compute1
```

#### acpi configuration

The following code will configure ACPI kernel modules correctly for *all* HP proliant hosts in $REGION_NAME:

```bash
osism-opstools-cmd ansible-playbook -i inventories/$REGION_NAME acpi.yml
```


#### Check metadata agent

The following code will check metadata agents in $REGION_NAME:

```bash
osism-opstools-cmd ansible-playbook -i inventories/$REGION_NAME playbook-start-check-delete-vm.yml
```

#### General admin tasks

```bash
osism-opstools-cmd ansible -i inventories/$REGION_NAME all -a "docker ps -a"  -l compute1
```

