#!/bin/sh
cd "$('dirname' '--' "${0}")"

C(){
    mkdir -pv -- "$('dirname' -- "${2}")"
    rm -vf -- "${2}"
    cp -vf -- "./${1}" "${2}"
}

D(){
    rsync -avh --progress "./${1}" "${2}"
}

C 'myelisp' "./snippets/org-mode/myelisp"
D 'snippets' "${HOME}/.emacs.d/"

C './early-init.el' "${HOME}/.emacs.d/early-init.el"

C './init.el' "${HOME}/.emacs.d/init.el"
