#!/bin/sh
export PATH="/var/tmp/all/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
exec alacritty msg create-window ${@}
exit '0'
