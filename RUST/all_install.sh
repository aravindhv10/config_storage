#!/bin/sh
'./generic-1.sh' 'lsd'

'./generic-1.sh' 'fd'

'./generic-1.sh' 'bat'

'./generic-1.sh' 'uv'
pushd './uv/target/release'
    cp -vf -- uvx uv "${HOME}/exe/"
    ln '-vfs' -- './c_wrapper' "${HOME}/bin/uv"
    ln '-vfs' -- './c_wrapper' "${HOME}/bin/uvx"
popd
