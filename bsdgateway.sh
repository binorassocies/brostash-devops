#!/bin/sh
echo "Deploy a network gateway based on openbsd"
echo "Assume the box have two network interfaces: em0 and em1 configured"
INTERNAL_IP="10.4.4.1"
EXTERNAL_IP="10.0.2.40"
DEFAULT_GATEWAY="10.0.2.2"
LAN_NET="10.4.4.0/24"
LAN_SUBNET="10.4.4"
DHCP_RANGE_START="100"
DHCP_RANGE_END="250"
INT_NIC="em1"
EXT_NIC="em0"
FORWARD_DNS="8.8.8.8"

echo "Updating the internal interface config!"
echo "inet $INTERNAL_IP 255.255.255.0 NONE -inet6" > /etc/hostname.$INT_NIC
echo "inet $EXTERNAL_IP 255.255.255.0 NONE -inet6" > /etc/hostname.$EXT_NIC
echo $DEFAULT_GATEWAY > /etc/mygate

sh /etc/netstart

echo "net.inet.ip.forwarding=1
net.inet.ip.mforwarding=0
net.inet6.ip6.forwarding=0
net.inet6.ip6.mforwarding=0
kern.maxclusters=128000
net.bpf.bufsize=1048576" >> /etc/sysctl.conf

sysctl net.inet.ip.forwarding=1
sysctl net.inet.ip.mforwarding=0
sysctl net.inet6.ip6.forwarding=0
sysctl net.inet6.ip6.mforwarding=0
sysctl kern.maxclusters=128000
sysctl net.bpf.bufsize=1048576

echo "configuring the pf firewall!"

echo "ext_if=\"$EXT_NIC\"
int_if = \"$INT_NIC\"
lan_net = \"$LAN_NET\"

set skip on lo0
match in all scrub (no-df)

block log all
block in quick from urpf-failed

pass in quick on \$ext_if inet proto tcp from any to any port = ssh keep state

pass in on \$int_if from \$lan_net
pass out on \$int_if to \$lan_net

pass out on \$ext_if proto { tcp udp icmp } all modulate state

match out log on \$ext_if from \$int_if:network nat-to (\$ext_if:0)
" > /etc/pf.conf

pfctl -f /etc/pf.conf

echo "Configuring unbound dns cache!"

echo "# \$OpenBSD: unbound.conf,v 1.4 2014/04/02 21:43:30 millert Exp \$

server:
        interface: 127.0.0.1
        interface: $INTERNAL_IP
        do-ip6: no
        verbosity: 3
        log-queries: yes

        access-control: 0.0.0.0/0 refuse
        access-control: 127.0.0.0/8 allow
        access-control: $LAN_NET allow
        access-control: ::0/0 refuse
        access-control: ::1 refuse

        hide-identity: yes
        hide-version: yes

forward-zone:
        name: "."                               
        forward-addr: $FORWARD_DNS
" > /var/unbound/etc/unbound.conf
rcctl enable unbound
rcctl start unbound

echo "Configuring DHCP server!"

echo "shared-network LOCALHOST-BIZ {
        default-lease-time 86400;
        option  domain-name \"LOCALHOST.biz\";
        option  domain-name-servers $INTERNAL_IP;

        subnet $LAN_SUBNET.0 netmask 255.255.255.0 {
                option subnet-mask 255.255.255.0;
                option broadcast-address $LAN_SUBNET.255;
                option routers $INTERNAL_IP;
                range $LAN_SUBNET.$DHCP_RANGE_START $LAN_SUBNET.$DHCP_RANGE_END;
        }
}

" > /etc/dhcpd.conf

touch /var/db/dhcpd.leases

echo "dhcpd_flags=\"$INT_NIC\"" >> /etc/rc.conf.local

rcctl enable dhcpd
rcctl start dhcpd

echo "nameserver 127.0.0.1" > /etc/resolv.conf

