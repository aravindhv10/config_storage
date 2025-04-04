#!/bin/sh
C(){
    mkdir -pv -- "$('dirname' -- "${2}")"
    rm -vf -- "${2}"
    cp -vf -- "${1}" "${2}"
}

C './early-init.el' "${HOME}/emacs.d/early-init.el"

C './init.el' "${HOME}/emacs.d/init.el"
