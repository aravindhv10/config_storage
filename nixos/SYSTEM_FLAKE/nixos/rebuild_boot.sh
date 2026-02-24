#!/bin/sh
export TMPDIR='/tmp'
nixos-rebuild boot --flake '.#nixos'
echo '#### DONE ####'
