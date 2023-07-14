#!/bin/bash -e

chmod 600 /root/wireguard/conf/wg0.conf
wg-quick up ./wireguard/conf/wg0.conf