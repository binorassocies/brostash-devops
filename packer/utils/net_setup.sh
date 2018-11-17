#!/bin/sh
set -e
set -x

get_nics(){
  if [  -f /usr/bin/netstat ]; then
    EXT_NIC=`/usr/bin/netstat -rn -f inet | grep "^[^[:blank:]*]" | tail -n +3 |  grep "^default" | awk '{print $8}'`
  elif [  -f /sbin/ip ]; then
    EXT_NIC=`/sbin/ip route | grep "^default" | awk '{print $5}'`
  fi
  if [ -z "$EXT_NIC" ]; then
    echo "Not external NIC found!"
    exit
  fi
  if [  -f /sbin/ifconfig ]; then
    ALL_NIC=`/sbin/ifconfig -a | grep "^[^[:blank:]*]" | grep -e BROADCAST | awk '{print $1}' | awk -F':' '{print $1}' | uniq`
  elif [  -f /sbin/ip ]; then
    ALL_NIC=`/sbin/ip -a addr | grep "^[^[:blank:]*]" | grep -e BROADCAST | awk '{print $2}' | awk -F':' '{print $1}' | uniq`
  fi

  INT_NIC=""
  INT_IP=""

  c=1
  for dd in $ALL_NIC
  do
    echo $dd
    if [ "$EXT_NIC" != "$dd" ]; then
      INT_NIC="$INT_NIC $dd"
      d_ip="192.168.1$c.1"
      INT_IP="$INT_IP $d_ip"
    fi
    c=`expr $c + 1`
  done

  if [ -z "$INT_NIC" ]; then
    echo "Not internal NIC found!"
    exit
  fi
}

bsd_net_config(){
  get_nics

  c=1
  for d in $INT_NIC
  do
    ip=`echo $INT_IP | awk -v var="$c" '{ print $var }'`
    if [ -z "$ip" ]; then
      echo "dhcp" > /etc/hostname.$d
    else
      ip_head=`echo $ip | cut -d "." -f 1,2,3`
      echo "inet $ip 255.255.255.0 NONE -inet6" > /etc/hostname.$d
    fi
    c=`expr $c + 1`
  done
  sh /etc/netstart
}

deb_net_config(){
  get_nics
  c=1
  for d in $INT_NIC
  do
    ip=`echo $INT_IP | awk -v var="$c" '{ print $var }'`
    echo "auto $d" > /etc/network/interfaces.d/$d
    if [ -z "$ip" ]; then
      echo "iface $d inet dhcp" >> /etc/network/interfaces.d/$d
    else
      ip_head=`echo $ip | cut -d "." -f 1,2,3`
      echo "iface $d inet static
      address $ip
      netmask 255.255.255.0" >> /etc/network/interfaces.d/$d
      set +e
      if [ -f /etc/dhcpcd.conf ]; then
        FOUND=`grep -c -P "^denyinterfaces $d" /etc/dhcpcd.conf`
      else
        FOUND="0"
      fi
      set -e
      if [ $FOUND -eq 0 ]; then
        echo "denyinterfaces $d" >> /etc/dhcpcd.conf
      fi
    fi
    ifdown $d
    ifup $d
    c=`expr $c + 1`
  done
}

if [ "$(id -u)" != "0" ]
then
   echo "This script must be run as root" 1>&2
   exit 1
fi

SYS_OS=`uname -a | awk '{ print $1 }'`
if [ -f /etc/os-release ]
then
    SYS_OS=`cat /etc/os-release | grep '^ID=' | awk -F=  '{ print $2 }'`
fi

echo $SYS_OS

case "$SYS_OS" in
  ubuntu|debian|raspbian)
    echo "Running script for Debian flavor!"
    deb_net_config
    ;;
  OpenBSD)
    echo "Running script for OpenBSD!"
    bsd_net_config
    exit
    ;;
esac
