#!/bin/sh
. '/usr/lib/sdk/llvm18/enable.sh'
export CC='clang'
export CXX='clang++'
cd build
make -j4
exit '0'
