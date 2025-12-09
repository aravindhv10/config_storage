#!/bin/sh
cd "$(dirname -- "${0}")"
'./build_container.sh' 'CUDA_UBUNTU/0_base'
'./build_container.sh' 'CPU/1_install_packages'
'./build_container.sh' 'CPU/2_install_rust'
'./build_container.sh' 'CPU/3_good_setup'
'./build_container.sh' 'CPU/4_python'
'./build_container.sh' 'CUDA_UBUNTU/5_libtorch'
'./build_container.sh' 'CUDA_UBUNTU_OFFICIAL/6_pytorch'
exit '0'
