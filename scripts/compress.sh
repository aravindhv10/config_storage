#!/bin/sh
cd "$('dirname' '--' "${0}")"
OUT="$('/bin/pwd').squashfs-zstd"
'rm' '-vf' '--' "${OUT}"
'mksquashfs' '.' "${OUT}" '-comp' 'zstd' '-Xcompression-level' '18' '-b' '1048576' '-always-use-fragments' '-keep-as-directory'
exit '0'
