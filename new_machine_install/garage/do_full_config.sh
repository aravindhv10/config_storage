#!/bin/sh
cd "$('dirname' -- "${0}")"

get_ip(){
    ip address show dev enp3s0 \
    | grep inet | tr ' ' '\n' \
    | grep '10\.10\.8\.../24$' \
    | cut -d '/' -f1
}

sudo '-A' './gen_config.sh' "$(get_ip)" "$(./gen_secret.sh)"
