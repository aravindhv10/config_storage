#!/bin/sh
cd "$(dirname -- "${0}")"
'./build_container.sh' 'CPU/2_install_rust'
'./build_container.sh' 'CPU/3_good_setup'
exit '0'
