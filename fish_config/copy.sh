#!/bin/sh
cd "$(dirname -- "${0}")"
mkdir -pv -- "${HOME}/.config/fish/"
cp -vf -- './config.fish' "${HOME}/.config/fish/config.fish"
cp -vf -- './SUDO_ASKPASS' "${HOME}/SUDO_ASKPASS"
