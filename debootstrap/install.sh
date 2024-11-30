#!/bin/bash
export SUDO_ASKPASS="${HOME}/SUDO_ASKPASS"
export DEBIAN_FRONTEND='noninteractive'

function set_up_repo  {
    pushd ../
    sudo -A mkdir -pv -- ./repo
    mountpoint ./repo && return
    sudo -A ln -vfs -- /dev/disk/by-partlabel/A_2_EXT4 ./repo/
    sudo -A mv -vf -- ./repo/A_2_EXT4 ./repo/link
    sudo -A mount -o ro ./repo/link ./repo
    ls ./repo
    popd
}

function install_deb {
    pushd ../
    sudo -A debootstrap --arch=amd64 --no-check-gpg --no-check-certificate stable "$(realpath .)" "file://$(realpath ./repo/everything/apt-mirror/MY_MIRRORS/DEBIAN)"
    popd
}

function do_bind {
    pushd ../
    sudo -A mount -o bind "${1}" ".${1}"
    popd
}

function do_bind_all {
    do_bind '/dev'
    do_bind '/dev/pts'
    do_bind '/dev/shm'

    do_bind '/proc'
    do_bind '/sys'
    do_bind '/tmp'
    do_bind '/run'
}

function do_unbind {
    pushd ../
    sudo -A umount ".${1}"
    popd
}

function do_unbind_all {
    do_unbind '/dev/pts'
    do_unbind '/dev/shm'
    do_unbind '/dev'

    do_unbind '/proc'
    do_unbind '/sys'
    do_unbind '/tmp'
    do_unbind '/run'
}

function do_copy_conf {
    sudo -A cp -vf -- './debian.list' '../etc/apt/sources.list.d/'
}

function do_apt_update {
    pushd ../
    sudo -A chroot ./ apt-get update
    popd
}

function do_apt_update_upgrade {
    pushd ../
    sudo -A chroot ./ apt-get update
    sudo -A chroot ./ apt-get -y dist-upgrade
    popd
}

function do_apt_install {
    pushd ../
    sudo -A chroot ./ apt-get install -y ${@}
    popd
}

function do_apt_search {
    pushd ../
    sudo -A chroot ./ apt-cache search ${@}
    popd
}

do_copy_conf
do_apt_update

do_apt_update_upgrade
