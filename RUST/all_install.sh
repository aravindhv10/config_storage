#!/bin/bash
'./generic-1.sh' 'miniserve'

'./generic-1.sh' 'igrep' 'ig'

'./generic-1.sh' 'alacritty'

'./generic-1.sh' 'atuin'

'./generic-1.sh' 'bat'

'./generic-1.sh' 'dust'

'./generic-1.sh' 'fd'

'./generic-1.sh' 'lsd'

'./generic-1.sh' 'nushell' 'nu'

'./generic-1.sh' 'ripgrep' 'rg'

'./generic-1.sh' 'ruff'

'./generic-1.sh' 'skim' 'sk'

'./generic-1.sh' 'starship'

'./generic-1.sh' 'yazi'

'./generic-1.sh' 'zellij'

'./generic-1.sh' 'zoxide'

'./generic-1.sh' 'uv'
pushd './uv/target/release'
    cp -vf -- uvx uv "${HOME}/exe/"
    ln '-vfs' -- './c_wrapper' "${HOME}/bin/uv"
    ln '-vfs' -- './c_wrapper' "${HOME}/bin/uvx"
popd

'./generic-1.sh' './helix' 'hx'

'./generic-1.sh' 'bottom' 'btm'

pushd "${HOME}/exe"
    find ./ -type f \
        | sed 's@^@("ldd" "@g ; s@$@")@g' \
        | sh \
        | sed 's@\t@ @g' \
        | grep '=>' \
        | grep ' (0x' \
        | grep ')$' \
        | tr ' ' '\n' \
        | grep '/lib' \
        | sort \
        | uniq \
        | sed 's@^@("cp" "-vn" "@g;s@$@" "./")@g' \
        | sh ;
popd
