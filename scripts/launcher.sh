#!/bin/sh
export PATH="/var/tmp/all/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
exec "$(fd . '/var/tmp/all/bin' '/var/tmp/flatpak.dir/install/var/lib/flatpak/exports/bin/' '/usr/local/sbin' '/usr/local/bin' '/usr/sbin' '/usr/bin' '/sbin' '/bin' "${HOME}/bin" -t l -t f | sk)"
exit '0'
