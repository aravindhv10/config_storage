#!/bin/sh
cd "$(dirname -- "${0}")"
export LIBTORCH_USE_PYTORCH=1
export RUSTFLAGS="-C target-cpu=native"
rm -rf -- 'build'
mkdir -pv -- 'build'
cd 'build'
cmake ..
make -j
