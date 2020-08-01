#! /bin/bash


VERSION_FILE=/etc/ovpninfo
VERSION="1.0-debian10"
current_dir=$(pwd)

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

read -p "Server SSH port (default 22):" SSH_PORT;
if [[ "$SSH_PORT" == "" ]];then
        SSH_PORT=22;
fi

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
echo "Server SSH port:" $SSH_PORT;
echo "Server public port:" $SERVER_PORT;
echo "Server vpn users IP network:" $SERVER_VPN_LAN;
echo "Server LAN IP network:" $SERVER_LAN;
read -p "All vars right?(y/any key). If 'y', installing has been started: " vars_true;

if [[ "$vars_true" != "y" ]];then
        echo "Install stopped!";
        exit 1;
fi


#install pachedges
apt install openvpn htop wget unzip htop vim wget net-tools curl sudo git iptables-persistent -y;
systemctl enable openvpn-server@server;
cp iptables /etc/iptables/rules.v4;

#write data to example iptables file and move it
sed -i "s/SERVER_PORT/$SERVER_PORT/" iptables;
sed -i "s/SSH_PORT/$SSH_PORT/" iptables;



#change ssh port
sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config;
sed -i "s/Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config;


#install easy-rsa
cd /tmp;
wget https://github.com/OpenVPN/easy-rsa/archive/master.zip;
unzip master.zip;
cp -a easy-rsa-master/easyrsa3 /etc/openvpn/easy-rsa;

#back to installer dir and move oVPN vars file
cd $current_dir;
mv vars /etc/openvpn/easy-rsa/vars;

#create needs directory
mkdir /etc/openvpn/ccd
mkdir /etc/openvpn/clients
mkdir /etc/openvpn/scripts
rm -rf /etc/openvpn/client

#move scripts file and give him exec
mv deluser.sh newuser.sh /etc/openvpn/scripts/
chmod u+x /etc/openvpn/scripts/*

#move cfg file
sed -i "s/remote SERVER_IP SERVER_PORT/remote $SERVER_IP $SERVER_PORT/" template-client.conf;
sed -i "s/port 1194/port $SERVER_PORT/" server.conf;
sed -i "s/server 10.1.0.0 255.255.255.0/server $SERVER_VPN_LAN/" server.conf;
sed -i "s/push \"route 10.6.86.0 255.255.255.0\"/push \"route $SERVER_LAN\"/" server.conf;
mv server.conf /etc/openvpn/server/server.conf;
mv template-client.conf /etc/openvpn/template-client.conf;

#gen CA certs tls etc
cd /etc/openvpn;
./easy-rsa/easyrsa init-pki;
./easy-rsa/easyrsa build-ca nopass;
./easy-rsa/easyrsa gen-dh;
openvpn --genkey --secret pki/ta.key;
./easy-rsa/easyrsa build-server-full ovpn nopass;
./easy-rsa/easyrsa gen-crl;

#enable forwarding and configure swap
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf;
echo "vm.swappiness=1" >> /etc/sysctl.conf;
sysctl -p;

echo "Install date:" >> $VERSION_FILE;
echo $(date) >> $VERSION_FILE;
echo "Version:" >> $VERSION_FILE;
echo $VERSION >> $VERSION_FILE;

echo "Install is done. Reboot server."
