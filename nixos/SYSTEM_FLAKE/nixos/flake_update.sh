#!/bin/sh
cd "$('dirname' -- "${0}")"
export NIX_CONFIG="access-tokens = github.com=$(cat ./PAT_token)"
sudo -E nixos-rebuild switch --upgrade
nix \
    '--extra-experimental-features' 'flakes' \
    '--extra-experimental-features' 'nix-command' \
    flake update \
;
exit '0'
