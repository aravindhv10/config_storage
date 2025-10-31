#!/bin/sh
cd "$(dirname -- "${0}")"
rm -rf -- /usr/local/install
cp -aspf -- "$(realpath .)" /usr/local/install
cd /usr/local/install
cp -alpf . ../
exec rm -rf -- /usr/local/install
