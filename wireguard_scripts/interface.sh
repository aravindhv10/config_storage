#!/bin/sh
. './config.sh'
ip link add wg0 type wireguard
ip addr add "${SELF_INTERNAL_IP}/24" dev wg0
