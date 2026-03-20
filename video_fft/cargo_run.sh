#!/bin/sh
cd "$(dirname -- "${0}")"
. './env.sh'
'./cargo_build.sh'
cargo run --release
