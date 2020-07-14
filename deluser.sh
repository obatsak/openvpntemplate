# check on exist username VAR
if [ "$1" == "" ];then
        echo "Usage: /etc/openvpn/scripts/deluser.sh [USERNAME]";
        exit 1;
fi


# set the variables we'll use later
DIR_CLIENT="/etc/openvpn/clients/$1"
# check on exist user
if [ -d "$DIR_CLIENT" ]; then
        echo "Revoking certs..."
        cd /etc/openvpn;
        /etc/openvpn/easy-rsa/easyrsa revoke $1;
        echo "Rewrite crl-verify..."
        /etc/openvpn/easy-rsa/easyrsa gen-crl;
        if [ "$?" != "0" ]; then
            echo "Error.";
            exit 1;
        else echo "Ok."
        fi
        echo "Remove user directory...";
        sudo rm -R $DIR_CLIENT;
        if [ "$?" != "0" ]; then
            echo "Error.";
            exit 1;
        else echo "Ok."
        fi
        echo "Restart openvpn-server...";
        systemctl restart openvpn-server@server;
else
        echo "User $1 not found!";
        exit 1;
fi

echo "Done. User deleted."
