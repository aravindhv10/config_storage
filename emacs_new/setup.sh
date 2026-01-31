#!/bin/sh
. "${HOME}/important_functions.sh"
cp -apf -- '.emacs.d' "${HOME}/"

GET_EMACS_PKG () {
    get_repo "${1}"
}

GET_EMACS_PKG 'https://github.com/Wilfred/elisp-refs.git'
GET_EMACS_PKG 'https://github.com/Wilfred/helpful.git'
GET_EMACS_PKG 'https://github.com/abo-abo/swiper.git'
GET_EMACS_PKG 'https://github.com/company-mode/company-mode.git'
GET_EMACS_PKG 'https://github.com/emacs-evil/evil-collection.git'
GET_EMACS_PKG 'https://github.com/emacs-evil/evil.git'
GET_EMACS_PKG 'https://github.com/magnars/dash.el.git'
GET_EMACS_PKG 'https://github.com/magnars/s.el.git'
GET_EMACS_PKG 'https://github.com/noctuid/annalist.el.git'
GET_EMACS_PKG 'https://github.com/rejeep/f.el.git'
