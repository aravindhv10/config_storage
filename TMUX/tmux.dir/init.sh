#!/bin/sh
rm -rf -- build
cp -apf -- source build
cd build
sh ./autogen.sh
./configure --help > ../configopts
