#!/bin/sh
C () {
    D="$(dirname -- "${2}")"
    mkdir -pv -- "${D}"
    chmod '0700' "${D}"
    cp -vf -- "${1}" "${2}"
    chmod '0400' "${2}"
    chmod '0500' "${D}"
}

R(){
    chmod '0700' "${1}"
    rm -vrf -- "${1}"
}

R "${HOME}/.ssh"

C './HOME,.ssh,id_ed25519' "${HOME}/.ssh/id_ed25519"

C './HOME,.ssh,id_ed25519.pub' "${HOME}/.ssh/id_ed25519.pub"

C './HOME,.ssh,known_hosts' "${HOME}/.ssh/known_hosts"
