#!/bin/bash
. '/usr/lib/sdk/rust-stable/enable.sh'
if test "${#}" '-ge' '2'
then
    FILE_NAME="${2}"
else
    FILE_NAME="${1}"
fi
pushd "${1}"
    'cargo' 'build' '--release'
    cp '-vf' -- "target/release/${FILE_NAME}" "${HOME}/exe/"
    ln '-vfs' -- './c_wrapper' "${HOME}/bin/${1}"
popd
