#!/bin/sh
wg set wg0 listen-port 443 private-key ./privatekey peer "${PEER_PUBLIC_KEY}" allowed-ips 10.0.0.2/32 endpoint "${IP}:${PORT}"
ip link set wg0 up
