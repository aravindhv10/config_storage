#!/bin/sh
pushd fd
    cargo build --release
    cp target/release/fd ~/exe/
    ln -vfs ./c_wrapper ~/bin/fd
popd
