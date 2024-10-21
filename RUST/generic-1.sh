#!/bin/sh
. '/usr/lib/sdk/rust-stable/enable.sh'
pushd "${1}"
    'cargo' 'build' '--release'
    cp '-vf' -- "target/release/${1}" "${HOME}/exe/"
    ln '-vfs' -- './c_wrapper' "${HOME}/bin/${1}"
popd
