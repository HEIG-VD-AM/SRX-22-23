#!/bin/bash -e

# !! This script has to be executed at the root of the project !!

cp ./root/main/mainsKey.pem ./root/main/mainsReq.pem ./root/main/mainsCert.pem ./root/main/caCert.pem ./root/main/ipsec/pems
cp ./root/main/farsKey.pem ./root/main/farsReq.pem ./root/main/farsCert.pem ./root/main/caCert.pem ./root/far/ipsec/pems
cp ./root/main/remoteKey.pem ./root/main/remoteReq.pem ./root/main/remoteCert.pem ./root/main/caCert.pem ./root/remote/ipsec/pems

#Remove copied pems
rm -f ./root/main/*.pem