#!/bin/sh
export TMPDIR='/tmp'
nixos-rebuild switch --flake '.#nixos'
echo '#### DONE ####'
