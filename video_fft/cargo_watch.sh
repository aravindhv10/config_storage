#!/bin/sh
cd "$(dirname -- "${0}")"
export LIBTORCH_USE_PYTORCH=1
cargo watch -x run
