#!/bin/sh
cd "$(dirname -- "${0}")"
mkdir -pv -- "${HOME}/.config/"
cp './starship.toml' "${HOME}/.config/"
exit '0'
