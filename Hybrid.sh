#!/bin/bash

# go to root
cd

# Change to Time GMT+8
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# Install Webmin
cd /root
curl --user Kiellez:Terbaek811 -L -O https://bitbucket.org/Kiellez/vps/downloads/jcameron-key.asc
apt-key add jcameron-key.asc
echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" >> /etc/apt/sources.list
apt-get update
apt-get -y install webmin

# Disable Webmin SSL
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin restart
cd

# Install Web Server
apt-get -y install nginx php5-fpm php5-cli
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
curl --user Kiellez:Terbaek811 -L https://bitbucket.org/Kiellez/vps/downloads/nginx.conf -o /etc/nginx/nginx.conf
mkdir -p /home/vps/public_html
echo "<pre>Setup by Kiellez</pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
curl --user Kiellez:Terbaek811 -L https://bitbucket.org/Kiellez/vps/downloads/vps.conf -o /etc/nginx/conf.d/vps.conf
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php5/fpm/pool.d/www.conf
service php5-fpm restart
service nginx restart

# Install Vnstat
apt-get -y install vnstat
vnstat -u -i eth0
chown -R vnstat:vnstat /var/lib/vnstat
service vnstat restart

# Install Vnstat GUI
cd /home/vps/public_html/
curl --user Kiellez:Terbaek811 -L -O https://bitbucket.org/Kiellez/vps/downloads/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
sed -i "s/\$iface_list = array('eth0', 'sixxs');/\$iface_list = array('eth0');/g" config.php
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php
sed -i "s/\$locale = 'en_US.UTF-8';/\$locale = 'en_US.UTF+8';/g" config.php
cd

# Install OpenVpn
apt-get -y install openvpn
curl --user Kiellez:Terbaek811 -L https://bitbucket.org/Kiellez/vps/downloads/hybrid.tar -o /etc/openvpn/openvpn.tar
cd /etc/openvpn/
tar xf openvpn.tar
curl --user Kiellez:Terbaek811 -L https://bitbucket.org/Kiellez/vps/downloads/1194.conf -o /etc/openvpn/1194.conf
service openvpn restart
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
curl --user Kiellez:Terbaek811 -L https://bitbucket.org/Kiellez/vps/downloads/iptables.up.rules -o /etc/iptables.up.rules
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | grep -v '192.168'`;
MYIP2="s/xxxxxxxxx/$MYIP/g";
sed -i $MYIP2 /etc/iptables.up.rules;
iptables-restore < /etc/iptables.up.rules
service openvpn restart

# configure openvpn client config
cd /etc/openvpn/
curl --user Kiellez:Terbaek811 -L https://bitbucket.org/Kiellez/vps/downloads/client.conf -o /etc/openvpn/client.ovpn
sed -i $MYIP2 /etc/openvpn/client.ovpn
openvpn --genkey --secret /etc/openvpn/ta.key
echo '<tls-auth>' >> /etc/openvpn/client.ovpn
cat /etc/openvpn/ta.key >> /etc/openvpn/client.ovpn
echo '</tls-auth>' >> /etc/openvpn/client.ovpn
tar cf client.tar client.ovpn
cp client.tar /home/vps/public_html/
cd
service openvpn restart

# Install Squid
apt-get -y install squid3
cp /etc/squid3/squid.conf /etc/squid3/squid.conf.orig
curl --user Kiellez:Terbaek811 -L https://bitbucket.org/Kiellez/vps/downloads/squid.conf -o /etc/squid3/squid.conf
MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | grep -v '192.168'`;
sed -i s/xxxxxxxxx/$MYIP/g /etc/squid3/squid.conf;
service squid3 restart

# install essential package
apt-get -y install sysv-rc-conf apt-file
apt-get -y install libexpat1-dev libxml-parser-perl

# update apt-file
apt-file update

# remove unused
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;

# disable exim
service exim4 stop
sysv-rc-conf exim4 off

# Install Firewall
apt-get -y install ufw
ufw allow 22,80,81,222,443,8080,10000,60000/tcp
yes | ufw enable

# User Status
cd
curl --user Kiellez:Terbaek811 -L -O https://bitbucket.org/Kiellez/vps/downloads/users
chmod +x status

# About
clear
echo "Script ini hanya mengandungi :-"
echo "-Webmin"
echo "-OpenVpn"
echo "-Web Server"
echo "-Firewall"
echo "-Squid Proxy"
echo "-Vnstat"
echo "Jika ada tambahan sila tambah sendiri ye =)"
echo " "
echo "Created by Kiellez"
echo "TimeZone   :  Malaysia"
echo "Vnstat     :  http://$MYIP:81/vnstat"
echo "Webmin     :  http://$MYIP:10000"
echo "Config     :  http://$MYIP:81/client.tar"
echo "To Check Users Status please type ./users"
