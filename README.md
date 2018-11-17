# DevOps playbooks and templates for BroStash

This repository holds a collection of Ansible playbooks and Packer templates. The playbooks cover the deployment of a LAN gateway with a DNS cache/forwarder and DHCP servers. They also cover the deployment of a Bro IDS based network sensor and Elastic stack nodes. The Ansible playbooks are used by a collection of Packer templates to build Virtual Machines with the above mentioned services. These playbooks and templates can be used in combination with the [BroStash](https://github.com/binorassocies/brostash) distribution to create an ELK stack data processing pipeline.

## Ansible
[Ansible playbooks](ansible/README.md)

## Packer
[Packer templates](packer/README.md)
