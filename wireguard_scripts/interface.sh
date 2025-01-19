#!/bin/sh
ip link add wg0 type wireguard
ip addr add 10.0.0.1/24 dev wg0
