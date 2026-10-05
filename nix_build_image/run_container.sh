#!/bin/sh
cd "$('dirname' -- "${0}")"
podman run \
    '--rm' \
    '--interactive' \
    '--tty' \
    -v "$(realpath .):/data" \
    -v "$(realpath "${HOME}/GITHUB"):/root/GITHUB" \
    'nixbuilder' \
    'bash' ;
