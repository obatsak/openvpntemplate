# check on exist username VAR
if [ "$1" == "" ];then
        echo "Usage: /etc/openvpn/scripts/newuser.sh [USERNAME]";
        exit 1;
fi


# set the variables we'll use later
DIR_CLIENT="/etc/openvpn/clients/$1"
# check on exist user
if [ -d "$DIR_CLIENT" ]; then
    echo "$1 already exists, see $DIR_CLIENT";
    exit 1;
fi


# create the certificate and key
cd "/etc/openvpn"
echo "Create the certificate and key..."
/etc/openvpn/easy-rsa/easyrsa build-client-full "$1" nopass >/dev/null 2>&1

if [ "$?" != "0" ]; then
    echo "Error.";
    exit 1;
else echo "Ok."
fi



# create a directory to save all the files
echo "Create a directory to save all the files..."
mkdir -p "${DIR_CLIENT}"

if [ "$?" != "0" ]; then
    echo "Error.";
    exit 1;
else echo "Ok."
fi


# copy certificate, key, tls auth and CA
echo "Copy certificate, key, tls auth and CA..."
cp "/etc/openvpn/pki/ca.crt" "$DIR_CLIENT/ca.crt"
cp "/etc/openvpn/pki/ta.key" "$DIR_CLIENT/ta.key"
cp "/etc/openvpn/pki/issued/$1.crt" "$DIR_CLIENT/"
cp "/etc/openvpn/pki/private/$1.key" "$DIR_CLIENT/"

if [ "$?" != "0" ]; then
    echo "Error.";
    exit 1;
else echo "Ok."
fi

# copy and customize the client configuration
echo "Copy and customize the client configuration..."
cp "/etc/openvpn/template-client" "${DIR_CLIENT}/$1.ovpn"

if [ "$?" != "0" ]; then
    echo "Error.";
    exit 1;
else echo "Ok."
fi


# inserting certs into ovpn
echo "Inserting certs into ovpn config..."
# ca
echo "<ca>" >> "${DIR_CLIENT}/$1.ovpn"
cat "$DIR_CLIENT/ca.crt" >> "${DIR_CLIENT}/$1.ovpn"
echo "</ca>" >> "${DIR_CLIENT}/$1.ovpn"
# cert
echo "<cert>" >> "${DIR_CLIENT}/$1.ovpn"
sed -n '/-----BEGIN CERTIFICATE-----/,$p' "$DIR_CLIENT/$1.crt" >> "${DIR_CLIENT}/$1.ovpn"
echo "</cert>" >> "${DIR_CLIENT}/$1.ovpn"
# key
echo "<key>" >> "${DIR_CLIENT}/$1.ovpn"
cat "$DIR_CLIENT/$1.key" >> "${DIR_CLIENT}/$1.ovpn"
echo "</key>" >> "${DIR_CLIENT}/$1.ovpn"
# tls
echo "<tls-auth>" >> "${DIR_CLIENT}/$1.ovpn"
sed -n '/-----BEGIN OpenVPN Static key V1-----/,$p' "$DIR_CLIENT/ta.key" >> "${DIR_CLIENT}/$1.ovpn"
echo "</tls-auth>" >> "${DIR_CLIENT}/$1.ovpn"

echo "Done. User created. Use ${DIR_CLIENT}/$1.ovpn for connect him."
