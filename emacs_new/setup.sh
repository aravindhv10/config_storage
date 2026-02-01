#!/bin/sh
cd "$(dirname -- "${0}")"
mkdir -pv -- "${HOME}/.emacs.d/snippets/"

. "${HOME}/important_functions.sh"

GET_EMACS_PKG () {
    get_repo "${1}"
}

. './get_packages.sh'

rsync -avh --progress "${HOME}/GITHUB/aravindhv10/config_storage/emacs_new/.emacs.d/" "${HOME}/.emacs.d/"
rsync -avh --progress "${HOME}/GITHUB/AndreaCrotti/yasnippet-snippets/snippets/" "${HOME}/.emacs.d/snippets/"
rsync -avh --progress "${HOME}/GITHUB/aravindhv10/config_storage/emacs_new/snippets/" "${HOME}/.emacs.d/snippets/"
