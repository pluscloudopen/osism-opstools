#
# Openstack container with addtional tools like Vault and Ansible
# Used for shortlived automation jobs. Do not use it for long running services
#
FROM ubuntu:focal

MAINTAINER openstack-squad@plusserver.com

ENV DEBIAN_FRONTEND=noninteractive
RUN groupadd -g 45000 dragon && useradd -g 45000 -u 45000 -s /bin/bash -c "Openstack User" -d "/home/dragon" -m dragon && \
    apt update && apt -yq install sudo python3-pip git openssh-client libcap2-bin jq lsb-release software-properties-common curl dumb-init && \
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - && \
    apt-add-repository "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt update && apt -yq install vault && \
    apt clean

RUN setcap cap_ipc_lock= /usr/bin/vault
COPY docker-files /


# Install Python/Ansible stuff. We need Ansible >= 2.11. This currently only available via Python pip installation
# Note openstacksdk version: https://storyboard.openstack.org/#!/story/2010103
RUN pip install --upgrade requests ansible hvac python-gitlab python-openstackclient python-barbicanclient \
    python-cinderclient python-designateclient python-glanceclient python-heatclient python-neutronclient \
    python-novaclient python-octaviaclient openstacksdk==0.61 && \
    ansible-galaxy collection install community.general openstack.cloud

USER dragon
WORKDIR /workspace

VOLUME ["/workspace"]

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["openstack"]

