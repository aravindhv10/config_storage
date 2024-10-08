#!/bin/sh
. '/usr/lib/sdk/llvm18/enable.sh'
export CC='clang'
export CXX='clang++'
rm -rf -- build
cp -apf -- source build
cd build
sh ./autogen.sh
./configure "--prefix=$(cd ../ && realpath .)/install" '--enable-sixel'
exit '0'
