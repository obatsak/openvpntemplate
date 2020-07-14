#! /bin/bash


VERSION_FILE=/etc/ovpninfo
VERSION="1.0"

#check root
if [[ "$UID" != "0" ]];then
        echo "You need be root!";
        exit 1;
fi

if [[ -f "$VERSION_FILE" ]]; then
    echo "oVPN already install!";
    echo $(cat $VERSION_FILE);
    exit 1;
fi

#get VARs
read -p "Server public ip address:" SERVER_IP;

read -p "Server public port (default 1194):" SERVER_PORT;
if [[ "$SERVER_PORT" == "" ]];then
        SERVER_PORT=1194;
fi

read -p "Server vpn users IP network (default 10.1.0.0 255.255.254.0):" SERVER_VPN_LAN;
if [[ "$SERVER_VPN_LAN" == "" ]];then
        SERVER_VPN_LAN="10.1.0.0 255.255.254.0";
fi

read -p "Server LAN IP network (default 10.6.86.0 255.255.255.0):" SERVER_LAN;
if [[ "$SERVER_LAN" == "" ]];then
        SERVER_LAN="10.6.86.0 255.255.255.0";
fi

#check VARs
echo "Check VARs:";
echo "Server public ip address:" $SERVER_IP;
echo "Server public port:" $SERVER_PORT;
echo "Server vpn users IP network:" $SERVER_VPN_LAN;
echo "Server LAN IP network:" $SERVER_LAN;
read -p "All vars right?(y/any key). If 'y', installing has been started: " vars_true;

if [[ "$vars_true" != "y" ]];then
        echo "Install stopped!";
        exit 1;
fi

#disable selinux
setenforce 0;
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config;

#stop and disable firewalld
systemctl stop firewalld.service && systemctl disable firewalld.service

