#!/bin/sh
cd "$(dirname -- "${0}")"
. './env.sh'
# './generate_rs_bindings.sh'
exec cargo build '--release'
