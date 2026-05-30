#!/bin/sh
export TMPDIR='/tmp'
export NIX_CONFIG="access-tokens = github.com=$(cat ./PAT_token)"
nixos-rebuild boot --flake '.#nixos'
echo '#### DONE ####'
