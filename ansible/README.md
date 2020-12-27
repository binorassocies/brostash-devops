# Ansible playbooks
This directory holds a collection of Ansible playbooks to build a network gateway/sensor and Elastic stack (Elasticsearch/Logstash/Kibana) nodes. For the network gateway and sensor, the playbooks run on both Debian and OpenBSD. The Elastic/Logstash playbooks works only on

## Gateway and Access Point
***00_gateway***: tasks to deploy a network gateway. The system will includes a DHCP, DNS, HTTP and Samba server. On an OpenBSD host, an NFS file share will be also deployed. The DNS is a caching/forwarding server using unbound. It is forwarding the DNS queries using DNS over TLS.

*Deploy with*: On a local system
```
cd 00_gateway
ansible-playbook -i ../inventory gate.yml
```
The directory contains also a playbook to deploy a raspberry pi based AP.
*Deploy with*: On a local system
```
ansible-playbook -i ../inventory gate_ap.yml
```

## Sensor
***01_sensor***: tasks to deploy the Bro and suricata NIDS with optional support for PF_RING(Only on Debian host). The default configuration makes Bro/Suricata listen on all the host interfaces. To deploy Bro/Suricata without PF_RING support just comment the definition of the `pfring_dir` variables in the `bro_vars.yml` file.

To install PF_RING, on a local system *Run*:
```
cd 01_sensor
ansible-playbook -i ../inventory pfring.yml
```
To install Zeek/Bro, on a local system *Run*:
```
cd 01_sensor
ansible-playbook -i ../inventory bro.yml
```
To install Suricata, on a local system *Run*:
```
cd 01_sensor
ansible-playbook -i ../inventory suricta.yml
```

## Elastic
***02_elastik***: task to deploy an Elasticsearch node. The playbook installs also Kibana, curator (for cluster/index management) and configure Lighttpd as a reverse proxy for the elastic/Kibana http services. The Elasticsearch GeoIP ingest plugin is also installed. The playbook installs a default index mapping template. This mapping template and Elasticsearch configuration uses the playbook variables to set some of the nodes/index attributes.

*Run with*: On a local system
```
cd 02_elastik
ansible-playbook -i ../inventory elastik.yml

```
## Logstash
***03_logstash***: task to deploy a Logstash service. The playbook install logstash, download the latest version of the GeoIP and Public suffix versions. By default, it also deploy a simple event processing pipeline configuration. This configuration use the Beat input plugin and the Elasticsearch output plugin.

*Run with*: On a local system
```
cd 03_logstash
ansible-playbook -i ../inventory logstash.yml

```
