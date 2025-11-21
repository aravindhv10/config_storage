#!/bin/sh
cd "$(dirname -- "${0}")"
'./CUDA_UBUNTU/0_base/image_build.sh'
'./CPU/1_rust_builder/image_build.sh'
'./CPU/2_zsh/image_build.sh'
'./CPU/3_helix/image_build.sh'
'./CPU/4_python/image_build.sh'
'./CUDA_UBUNTU/5_libtorch/image_build.sh'
'./CUDA_UBUNTU/6_pytorch/image_build.sh'
exit '0'
