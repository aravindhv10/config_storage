#!/bin/sh
wg set wg0 listen-port 443 private-key ./privatekey peer "${PEER_KEY}" allowed-ips 10.0.0.2/24 endpoint "${IP}:${PORT}"
ip link set wg0 up
