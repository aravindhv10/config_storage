#!/bin/sh
cd "$(dirname -- "${0}")"
'./build_container.sh' 'CPU/0_base/Dockerfile'
'./build_container.sh' 'CPU/1_install_packages/Dockerfile'
'./build_container.sh' 'CPU/2_install_rust/Dockerfile'
'./build_container.sh' 'CPU/3_good_setup/Dockerfile'
'./build_container.sh' 'CPU/4_python/Dockerfile'
'./build_container.sh' 'CPU/5_libtorch/Dockerfile'
'./build_container.sh' 'CPU/6_Common_python_data/Dockerfile'
'./build_container.sh' 'CPU/7_deep_learning/Dockerfile'
exit '0'
