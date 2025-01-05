#!/bin/sh
DIR="$(realpath -- "$(dirname -- "${0}")")"
sudo dnsmasq \
    '--cache-size=1024' \
    "--addn-hosts=${DIR}/hosts" \
    "--resolv-file=${DIR}/resolv" \
;
# "--conf-file=${DIR}/dnsmasq.conf"
exit '0'
