#!/bin/sh
cd "$(dirname -- "${0}")"
'./build_container.sh' 'CUDA_UBUNTU/0_base'
'./build_container.sh' 'CPU/1_rust_builder'
'./build_container.sh' 'CPU/2_zsh'
'./build_container.sh' 'CPU/3_helix'
'./build_container.sh' 'CPU/4_python'
'./build_container.sh' 'CUDA_UBUNTU/5_libtorch'
'./build_container.sh' 'CUDA_UBUNTU/6_pytorch'
exit '0'
