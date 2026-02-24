#!/bin/sh
export TMPDIR='/var/tmp'
nixos-rebuild boot '.#nixos'
echo '#### DONE ####'
