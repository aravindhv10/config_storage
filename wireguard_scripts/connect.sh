#!/bin/sh
. './config.sh'

wg set wg0 \
    listen-port "${SELF_PORT}" \
    private-key ./privatekey \
    peer "${PEER_PUBLIC_KEY}" \
    allowed-ips "${PEER_INTERNAL_IP}/32" \
    endpoint "${PEER_EXTERNAL_IP}:${PEER_PORT}" \
;

ip link set wg0 up
