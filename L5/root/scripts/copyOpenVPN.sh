#!/bin/bash -e

# !! This script has to be executed at the root of the project !!

mkdir ./root/far/openvpn/crts -p
mkdir ./root/remote/openvpn/crts -p
mkdir ./root/host/openvpn/crts -p

mkdir ./root/far/openvpn/keys -p
mkdir ./root/remote/openvpn/keys -p
mkdir ./root/host/openvpn/keys -p

cp ./root/main/openvpn/ca/pki/issued/far.crt ./root/far/openvpn/crts/far.crt
cp ./root/main/openvpn/ca/pki/issued/remote.crt ./root/remote/openvpn/crts/remote.crt
cp ./root/main/openvpn/ca/pki/issued/host.crt ./root/host/openvpn/crts/host.crt

cp ./root/main/openvpn/ca/pki/ca.crt ./root/far/openvpn/crts/ca.crt
cp ./root/main/openvpn/ca/pki/ca.crt ./root/remote/openvpn/crts/ca.crt
cp ./root/main/openvpn/ca/pki/ca.crt ./root/host/openvpn/crts/ca.crt

cp ./root/main/openvpn/ca/pki/private/far.key ./root/far/openvpn/keys/far.key
cp ./root/main/openvpn/ca/pki/private/remote.key ./root/remote/openvpn/keys/remote.key
cp ./root/main/openvpn/ca/pki/private/host.key ./root/host/openvpn/keys/host.key

cp ./root/main/openvpn/ca/ta.key ./root/far/openvpn/keys/ta.key
cp ./root/main/openvpn/ca/ta.key ./root/remote/openvpn/keys/ta.key
cp ./root/main/openvpn/ca/ta.key ./root/host/openvpn/keys/ta.key

# Delete copied keys and cert
rm -f ./root/openvpn/ca/pki/issued/far.crt ./root/main/openvpn/ca/pki/issued/host.crt ./root/main/openvpn/ca/pki/issued/remote.crt
rm -f ./root/main/openvpn/ca/pki/private/far.key ./root/main/openvpn/ca/pki/private/remote.key ./root/main/openvpn/ca/pki/private/host.key