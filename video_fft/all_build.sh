#!/bin/sh
cd "$(dirname -- "${0}")"
./cmake_build.sh
./cargo_build.sh
