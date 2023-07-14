#!/bin/bash -e

cd ipsec/pems
cp caCert.pem /etc/swanctl/x509ca
cp farsKey.pem /etc/swanctl/private
cp farsCert.pem /etc/swanctl/x509
cp ../swanctl.conf /etc/swanctl/conf.d

pkill charon || true
/usr/lib/ipsec/charon &
sleep 1

swanctl --load-creds
swanctl --load-conns
