#!/bin/bash -e

# EASY-RSA
make-cadir /root/openvpn/ca && cd /root/openvpn/ca

export EASYRSA_BATCH=1
export EASYRSA_REQ_CN=main_server.local

./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa gen-dh

./easyrsa build-server-full server nopass
./easyrsa build-client-full far nopass
./easyrsa build-client-full remote nopass
./easyrsa build-client-full host nopass

openvpn --genkey tls-auth ta.key
