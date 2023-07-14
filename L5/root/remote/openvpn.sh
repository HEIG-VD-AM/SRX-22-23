#!/bin/bash -e

if [ ! -d "/dev/net" ]; then
    sudo mkdir -p /dev/net
    sudo mknod /dev/net/tun c 10 200
    sudo chmod 0666 /dev/net/tun
fi


openvpn /root/openvpn/conf/client.ovpn