#!/bin/sh
cd "$(dirname -- "${0}")"
export LIBTORCH_USE_PYTORCH=1
export RUSTFLAGS="-C target-cpu=native"
cargo watch -x run
