#!/bin/sh
NOW=$(date +%Y.%m.%d.%H.%M.%S)
SMB_SHARE_USER="toto"
SMB_SHARE_GRP="staff"
SMB_WORKGROUP="WORKGROUP"
SAMBA_VER="3.6.15p15"
export PKG_PATH=http://openbsd.cs.fau.de/pub/OpenBSD/`uname -r`/packages/`uname -m`/

pkg_add -r samba-$SAMBA_VER
ln -sf /usr/local/bin/python2.7 /usr/local/bin/python
ln -sf /usr/local/bin/python2.7-2to3 /usr/local/bin/2to3
ln -sf /usr/local/bin/python2.7-config /usr/local/bin/python-config
ln -sf /usr/local/bin/pydoc2.7  /usr/local/bin/pydoc

mkdir -p /pub
chmod -R 777 /pub
mkdir -p /smb
chmod -R 777 /smb

groupadd $SMB_SHARE_GRP
useradd $SMB_SHARE_USER
usermod -G $SMB_SHARE_GRP $SMB_SHARE_USER
echo "Please choose a password for the smb share user $SMB_SHARE_USER"
smbpasswd -a $SMB_SHARE_USER # pwd toto01

rcctl enable samba
cp /etc/samba/smb.conf /etc/samba/smb.conf.$NOW
echo "
[global]
   workgroup = $SMB_WORKGROUP
   server string = Samba Server
   security = user
   log file = /var/log/samba/smbd.%m
   max log size = 50
   dns proxy = no
   allow insecure wide links = no
   map to guest = bad user

[pub]
   comment = Public file space
   path = /pub
   read only = no
   public = yes
   force user = nobody
   max connections = 10

[share]
   comment = Shared directory
   path = /smb
   public = no
   valid users = $SMB_SHARE_USER, @$SMB_SHARE_GRP
   writable = yes
   browseable = yes
   create mask = 0765

" > /etc/samba/smb.conf

echo '
smbd_flags="-D"
nmbd_flags="-D"
' >> /etc/rc.conf.local

rcctl restart samba
