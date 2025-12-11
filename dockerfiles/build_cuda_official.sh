#!/bin/sh
cd "$(dirname -- "${0}")"
'./build_container.sh' 'CUDA_UBUNTU_OFFICIAL/6_pytorch'
exit '0'
