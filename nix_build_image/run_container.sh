#!/bin/sh
cd "$('dirname' -- "${0}")"
podman run \
    '--rm' \
    '--interactive' \
    '--tty' \
    'nixbuilder' \
    'bash' ;
