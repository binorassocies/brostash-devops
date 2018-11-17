# Packer templates
This directory holds a collection of Packer templates to build a network gateway/sensor and ELK (Elasticsearch/Logstash/Kibana) Virtual Machines. For the network gateway and sensor, the template build images for both the Debian and OpenBSD systems. The ELK Virtual Machine is built on the Debian distribution. The generated images are Virtualbox VM. They can be easily converted to Hyper-V or VmWare. When doing so, it's worth noting that the VM uses VBox internal network feature. Some tweaking of the network configuration on the target system will be necessary.

## Gateway/Sensor
The templates create a Debian 9/OpenBSD 6.3 images. It uses the Ansible playbook defined previously to setup a LAN gateway. In addition, It does install the Bro NIDS.

## Elastic
The template creates a Debian 9 image running the full ELK stack. It uses the Ansible playbook defined previously to install Elasticsearch, Kibana, Logstash and the lighttpd reverse proxy.
