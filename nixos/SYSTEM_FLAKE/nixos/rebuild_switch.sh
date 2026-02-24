#!/bin/sh
export TMPDIR='/var/tmp'
nixos-rebuild switch '.#nixos'
echo '#### DONE ####'
