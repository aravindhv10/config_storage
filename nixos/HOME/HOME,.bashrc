#!/bin/sh
export SHELL=bash

. "${HOME}/.shrc"

all_init_convenience () {
    starship init bash --print-full-init
    atuin init bash --disable-up-arrow 
    zoxide init bash
}

all_init_convenience > "/tmp/init_${$}"
. "/tmp/init_${$}"

rm -f -- "/tmp/init_${$}"
