#!/bin/sh
cd "$(dirname -- "${0}")"
cp -vf -- './wezterm.lua' "${HOME}/.wezterm.lua "
exit '0'
