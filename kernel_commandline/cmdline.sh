#!/bin/sh
tail -n +4 "${0}" | tr '\n' ' '
exit '0'

dolvm

zswap.max_pool_percent=80
zswap.zpool=zsmalloc
