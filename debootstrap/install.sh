#!/bin/bash
cd "$('dirname' '--' "${0}")"
. './functions.sh'

do_copy_conf
do_apt_update

do_apt_install_standard
