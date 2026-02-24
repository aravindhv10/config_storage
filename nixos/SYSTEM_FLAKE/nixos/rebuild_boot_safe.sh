#!/bin/sh
export TMPDIR='/var/tmp'
nixos-rebuild boot --flake '.#nixos'
echo '#### DONE ####'
