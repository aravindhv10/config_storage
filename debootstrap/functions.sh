#!/bin/bash
export SUDO_ASKPASS="${HOME}/SUDO_ASKPASS"
export DEBIAN_FRONTEND='noninteractive'

function set_up_repo  {
    mountpoint ../repo && return
    pushd ../
    sudo -A mkdir -pv -- ./repo
    sudo -A ln -vfs -- /dev/disk/by-partlabel/A_2_EXT4 ./repo/
    sudo -A mv -vf -- ./repo/A_2_EXT4 ./repo/link
    sudo -A mount -o ro ./repo/link ./repo
    ls ./repo
    popd
}

function install_deb_stable {
    ls ../usr/bin/dpkg && return
    pushd ../
    sudo -A debootstrap --arch=amd64 --no-check-gpg --no-check-certificate stable "$(realpath .)" "file://$(realpath ./repo/everything/apt-mirror/MY_MIRRORS/DEBIAN)"
    popd
}

function install_deb_testing {
    ls ../usr/bin/dpkg && return
    pushd ../
    sudo -A debootstrap --arch=amd64 --no-check-gpg --no-check-certificate testing "$(realpath .)" "file://$(realpath ./repo/everything/apt-mirror/MY_MIRRORS/DEBIAN)"
    popd
}

function do_bind {
    mountpoint "..${1}" && return
    pushd ../
    echo "binding ${1}"
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
    mountpoint "..${1}" || return
    pushd ../
    echo "unbinding ${1}"
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

function do_copy_conf_testing {
    sudo -A cp -vf -- './debian_testing.list' '../etc/apt/sources.list.d/'
}

function do_copy_conf_stable {
    sudo -A cp -vf -- './debian_stable.list' '../etc/apt/sources.list.d/'
}

function do_copy_conf_stable_backports {
    sudo -A cp -vf -- './debian_stable_backports.list' '../etc/apt/sources.list.d/'
}

function do_copy_conf_xanmod {
    sudo -A cp -vf -- './xanmod.list' '../etc/apt/sources.list.d/'
}

function do_copy_conf {
    do_copy_conf_testing
    do_copy_conf_xanmod
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

function do_apt_build {
    pushd ../
    sudo -A chroot ./ apt-get build-dep -y -f ${@}
    popd
}

function do_apt_install {
    pushd ../
    sudo -A chroot ./ apt-get install -m -y -f ${@}
    popd
}

function do_apt_search {
    pushd ../
    sudo -A chroot ./ apt-cache search ${@}
    popd
}

function do_apt_install_standard {
    do_apt_install eatmydata build-essential tmux flatpak vim neovim sudo squashfs-tools dnsmasq
    do_apt_install firmware-misc-nonfree amd64-microcode intel-microcode firmware-linux-nonfree firmware-linux live-task-non-free-firmware-pc live-task-non-free-firmware-server bluez-firmware firmware-iwlwifi
    do_apt_install lightdm sddm btrfs-progs lvm2 parted gdisk network-manager network-manager-gnome
    do_apt_install lxqt kwin-x11 kwin-wayland i3 htop aria2 rsync emacs mako-notifier btop
    do_apt_install 'linux-headers-6.6.69-x64v3-xanmod1' 'linux-image-6.6.69-x64v3-xanmod1'
    do_apt_install git git-lfs wayland-protocols libwayland-dev meson acpi fish zsh curl grim
    do_apt_install wayfire foot zram-tools systemd-zram-generator tasksel
    do_apt_install task-desktop task-gnome-desktop task-kde-desktop task-laptop task-lxqt-desktop task-ssh-server task-web-server task-xfce-desktop
    do_apt_build tmux flatpak
}

function write_fstab {
  cp ./fstab ../etc/fstab
}
