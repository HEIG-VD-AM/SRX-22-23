#!/bin/bash -e

# !! This script has to be executed at the root of the project !!

mkdir ./root/far/wireguard/keys/pub -p
mkdir ./root/remote/wireguard/keys/pub -p
mkdir ./root/host/wireguard/keys/pub -p

mkdir ./root/far/wireguard/keys/priv -p
mkdir ./root/remote/wireguard/keys/priv -p
mkdir ./root/host/wireguard/keys/priv -p

cp ./root/main/wireguard/keys/pub/pub_far ./root/far/wireguard/keys/pub/pub_far
cp ./root/main/wireguard/keys/pub/pub_remote ./root/remote/wireguard/keys/pub/pub_remote

cp ./root/main/wireguard/keys/priv/priv_far ./root/far/wireguard/keys/priv/priv_far
cp ./root/main/wireguard/keys/priv/priv_remote ./root/remote/wireguard/keys/priv/priv_remote

rm -f ./root/main/wireguard/keys/priv/priv_far
rm -f ./root/main/wireguard/keys/priv/priv_remote
rm -f ./root/main/wireguard/keys/pub/pub_far
rm -f ./root/main/wireguard/keys/pub/pub_remote