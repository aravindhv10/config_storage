#!/bin/sh
export TMPDIR='/var/tmp'
nixos-rebuild switch --flake '.#nixos'
echo '#### DONE ####'
