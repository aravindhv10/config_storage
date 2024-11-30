#!/bin/bash
cd "$('dirname' '--' "${0}")"
. './functions.sh'

set_up_repo

install_deb_testing

do_bind_all

do_copy_conf
do_apt_update

do_apt_install_standard

do_unbind_all
