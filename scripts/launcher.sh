#!/bin/sh
export PATH="/var/tmp/all/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
exec "$(fd . '/var/tmp/all/bin' "${HOME}/scripts/bin" "${HOME}/.nebius/bin" "${HOME}/bin" '/usr/local/sbin' '/usr/local/bin' '/usr/sbin' '/usr/bin' '/sbin' '/bin' '/app/bin' '/var/tmp/flatpak.dir/install/var/lib/flatpak/exports/bin/' | sk)"
exit '0'
