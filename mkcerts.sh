#!/bin/sh

if [ $# -ne 1 ]; then
    echo "Usage: $0 <device FQDN>"
    exit 1
fi

(
cat <<EOF
[req]
distinguished_name = req_distinguished_name
prompt = no
[req_distinguished_name]
C = US
ST = California
L = San Jose
O = Cisco
OU = MDT
CN = cisco.com
EOF
) > ca.cnf

openssl genrsa -out ${1}-ca.key > /dev/null 2>&1
openssl req -x509 -new -nodes -key ${1}-ca.key -days 365 -out ${1}-ca.crt -config ca.cnf > /dev/null 2>&1

(
cat <<EOF
[req]
distinguished_name = req_distinguished_name
prompt = no
req_extensions = v3_req

[req_distinguished_name]
C = US
ST = California
L = San Jose
O = Cisco
OU = MDT
CN = ${1}

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${1}
EOF
) > ${1}.cnf

openssl genrsa -out ${1}.key > /dev/null 2>&1
openssl req -new -key ${1}.key -out ${1}.csr -config ${1}.cnf
openssl x509 -req -in ${1}.csr -CA ${1}-ca.crt -CAkey ${1}-ca.key -CAcreateserial -out ${1}.crt > /dev/null 2>&1

rm ca.cnf ${1}.cnf

cat <<EOF
Configure the trustpoint using the following:

crypto pki import <trustpoint name 1> pem terminal password admin
 <paste contents of ${1}-ca.crt>
 <paste contents of ${1}.key>
EOF
