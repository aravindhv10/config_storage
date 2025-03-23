#!/bin/sh
cd "$('dirname' '--' "${0}")"

C () {
    sudo cp -vf -- "./${1}" "/etc/nixos/${1}"
}

C 'hardware-configuration.nix'

C 'configuration.nix'
