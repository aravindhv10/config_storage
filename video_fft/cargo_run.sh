#!/bin/sh
cd "$(dirname -- "${0}")"
. './env.sh'
'./all_build.sh'
cargo run --release
