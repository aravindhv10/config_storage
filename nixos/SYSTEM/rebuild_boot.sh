#!/bin/sh
export TMPDIR='/var/tmp'
nixos-rebuild boot
echo '#### DONE ####'
