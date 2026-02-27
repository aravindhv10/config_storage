#!/bin/sh
cd "$('dirname' -- "${0}")"
nix \
    '--extra-experimental-features' 'flakes' \
    '--extra-experimental-features' 'nix-command' \
    flake update \
;
exit '0'
