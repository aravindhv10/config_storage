#!/bin/sh
cd "$(dirname -- "${0}")"

export LIBTORCH_USE_PYTORCH=1
export RUSTFLAGS="-C target-cpu=native"

mkdir -pv -- 'target'
cd 'target'

rm -rf -- 'CMakeFiles'

unlink 'CMakeCache.txt'
unlink 'cmake_install.cmake'
unlink 'compile_commands.json'
unlink 'libmytorch.so'
unlink 'libmytorch.so.1.0'
unlink 'Makefile'

cmake .. 
make -j
cp -vf -- 'libmytorch.so' 'libmytorch.so.1.0' '/lib'
