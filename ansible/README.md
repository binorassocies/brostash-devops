# Ansible playbooks
This directory holds a collection of Ansible playbooks to build a network gateway/sensor and Elastic stack (Elasticsearch/Logstash/Kibana) nodes. For the network gateway and sensor, the playbooks run on both Debian and OpenBSD. The Elastic/Logstash playbooks works only on

## Gateway
***00_gateway***: tasks to deploy a network gateway. The system will includes a DHCP, DNS, HTTP and Samba server. On an OpenBSD host, an NFS file share will be also deployed. The DNS is a caching/forwarding server using unbound. It is forwarding the DNS queries using DNS over TLS.

*Run with*: On a local system
```
cd 00_gateway
ansible -i ../inventory gate.yml
```

## Sensor
***01_sensor***: tasks to deploy the Bro IDS with optional support for PF_RING(Only on Debian host). The default configuration makes Bro listen on all the host interfaces. To deploy Bro without PF_RING support just comment the definition of the `pfring_dir` variables in the `bro_vars.yml` file.

*Run with*: On a local system
```
cd 01_sensor
ansible -i ../inventory pfring.yml
ansible -i ../inventory bro.yml

```

## Elastic
***02_elastik***: task to deploy an Elasticsearch node. The playbook installs also Kibana, curator (for cluster/index management) and configure Lighttpd as a reverse proxy for the elastic/Kibana http services. The Elasticsearch GeoIP ingest plugin is also installed. The playbook installs a default index mapping template. This mapping template and Elasticsearch configuration uses the playbook variables to set some of the nodes/index attributes.

*Run with*: On a local system
```
cd 02_elastik
ansible -i ../inventory elastik.yml

```
## Logstash
***03_logstash***: task to deploy a Logstash service. The playbook install logstash, download the latest version of the GeoIP and Public suffix versions. By default, it also deploy a simple event processing pipeline configuration. This configuration use the Beat input plugin and the Elasticsearch output plugin.

*Run with*: On a local system
```
cd 03_logstash
ansible -i ../inventory logstash.yml

```
