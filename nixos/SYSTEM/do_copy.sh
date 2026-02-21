#!/bin/sh
cd "$('dirname' '--' "${0}")"

C () {
    export SUDO_ASKPASS="${HOME}/SUDO_ASKPASS"
    sudo -A cp -vf -- "./${1}" "/etc/nixos/${1}"
}

C 'rebuild_boot.sh'
C 'rebuild_switch.sh'

C 'configuration.nix'
C 'hardware-configuration.nix'
C 'kernel_config.nix'
