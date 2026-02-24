#!/bin/sh
export TMPDIR='/var/tmp'
nixos-rebuild switch
echo '#### DONE ####'
