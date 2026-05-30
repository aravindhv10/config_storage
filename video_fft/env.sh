#!/bin/sh
export LIBTORCH_BYPASS_VERSION_CHECK='1'
export LIBTORCH_USE_PYTORCH=1
export RUSTFLAGS="-C target-cpu=x86-64-v3 -C target-feature=+aes,+sse2"
