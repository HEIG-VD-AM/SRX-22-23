#!/bin/bash -e

mkdir /root/wireguard/keys/priv/ -p
mkdir /root/wireguard/keys/pub/ -p

# Main
wg genkey > /root/wireguard/keys/priv/private
wg pubkey < /root/wireguard/keys/priv/private > /root/wireguard/keys/pub/public

# FarS
wg genkey > /root/wireguard/keys/priv/priv_far
wg pubkey < /root/wireguard/keys/priv/priv_far > /root/wireguard/keys/pub/pub_far

# Remote
wg genkey > /root/wireguard/keys/priv/priv_remote
wg pubkey < /root/wireguard/keys/priv/priv_remote > /root/wireguard/keys/pub/pub_remote
