#!/bin/sh
echo "Deploy a network gateway based on openbsd"
echo "Assume the box have 3 network interfaces: em0 em1 em2 configured"
EXT_NIC="em0"
INT_NIC="em1 em2"
EXT_IP="10.0.2.40"
DEFAULT_GATEWAY="10.0.2.2"

INT_IP="192.168.56.1 10.0.0.1"
DHCP_RANGE="100:150 200:250"

echo "Updating the internal interface config!"

echo "inet $EXT_IP 255.255.255.0 NONE -inet6" > /etc/hostname.$EXT_NIC
echo $DEFAULT_GATEWAY > /etc/mygate

c=1
for x in $INT_NIC
do
    i_ip=`echo $INT_IP | awk -v var="$c" '{ print $var }'`
    echo "inet $i_ip 255.255.255.0 NONE -inet6" > /etc/hostname.$x
    chmod +x /etc/hostname.$x
    c=`expr $c + 1`
done

sh /etc/netstart


sh /etc/netstart

echo "net.inet.ip.forwarding=1" >> /etc/sysctl.conf

sysctl net.inet.ip.forwarding=1

echo "configuring the pf firewall!"
echo "ext_if=\"$EXT_NIC\"
set skip on lo0
match in all scrub (no-df)
block log all
block in quick from urpf-failed
pass in quick inet proto tcp from any to any port = ssh keep state
pass out on \$ext_if proto { tcp udp icmp } all modulate state" > /etc/pf.conf

for x in $INT_NIC
do
    echo "pass in on $x from $x:network" >> /etc/pf.conf
    echo "pass out on $x to $x:network" >> /etc/pf.conf
    echo "match out log on \$ext_if from $x:network nat-to (\$ext_if:0)" >> /etc/pf.conf
done

pfctl -f /etc/pf.conf
pfctl -sr

echo "Configuring unbound"
echo "#
server:
        interface: 127.0.0.1
        do-ip6: no
        verbosity: 3
        log-queries: yes
        access-control: 0.0.0.0/0 refuse
        access-control: 127.0.0.0/8 allow" > /var/unbound/etc/unbound.conf

for x in $INT_IP
do
  echo "          access-control: $x/24 allow"  >> /var/unbound/etc/unbound.conf
  echo "          interface: $x"  >> /var/unbound/etc/unbound.conf
done
echo "
        access-control: ::0/0 refuse
        access-control: ::1 refuse
        hide-identity: yes
        hide-version: yes
        do-not-query-localhost: no

include: /var/unbound/etc/unbound.conf.d/*.conf" >> /var/unbound/etc/unbound.conf

rcctl enable unbound
rcctl restart unbound

echo '###' > /etc/dhcpd.conf
c=1
for i in $INT_IP
do
  ip_head=`echo $i | cut -d "." -f 1,2,3`
  drange_s=`echo $DHCP_RANGE | awk -v var="$c" '{ print $var }'| cut -d ":" -f 1`
  drange_e=`echo $DHCP_RANGE | awk -v var="$c" '{ print $var }'| cut -d ":" -f 2`

  echo "shared-network LOCALHOST-LOCAL {
    default-lease-time 86400;
    option  domain-name \"LOCALHOST.LOCAL\";
    option  domain-name-servers $i;
    subnet $i netmask 255.255.255.0 {
      option subnet-mask 255.255.255.0;
      option routers $i;
      range $ip_head.$drange_s $ip_head.$drange_e;
    }
}" >> /etc/dhcpd.conf
c=`expr $c + 1`

done

echo "dhcpd_flags=\"$INT_NIC\"" >> /etc/rc.conf.local
rcctl enable dhcpd
rcctl restart dhcpd

echo "nameserver 127.0.0.1" > /etc/resolv.conf
