#!/bin/sh
export TMPDIR='/var/tmp'
export NIX_CONFIG="access-tokens = github.com=$(cat ./PAT_token)"
nixos-rebuild boot --flake '.#nixos'
echo '#### DONE ####'
