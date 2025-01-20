#!/bin/sh
. './config.sh'
wg set wg0 listen-port 443 private-key ./privatekey peer "${PEER_PUBLIC_KEY}" allowed-ips "${PEER_INTERNAL_IP}/32" endpoint "${PEER_EXTERNAL_IP}:${PORT}"
ip link set wg0 up
