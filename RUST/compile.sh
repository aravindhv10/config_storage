#!/bin/sh
. /usr/lib/sdk/rust-stable/enable.sh
pushd lsd
    cargo build --release
popd
