#!/bin/sh
cd "$(dirname -- "${0}")"
. './env.sh'
cargo watch -x run
