#!/bin/sh
cd "$(dirname -- "${0}")"

. "${HOME}/important_functions.sh"
cp -apf -- '.emacs.d' "${HOME}/"

GET_EMACS_PKG () {
    get_repo "${1}"
}

. './get_packages.sh'

mkdir -pv -- "${HOME}/.emacs.d/snippets/"
rsync -avh --progress "${HOME}/GITHUB/AndreaCrotti/yasnippet-snippets/snippets/" "${HOME}/.emacs.d/snippets/"
