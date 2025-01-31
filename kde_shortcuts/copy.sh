#!/bin/sh
cd "$(dirname -- "${0}")"
mkdir -pv -- "${HOME}/.local/share" "${HOME}/.config"
cp -vf    -- './kglobalshortcutsrc' "${HOME}/.config/"
cp -vapf  -- './applications'       "${HOME}/.local/share"
sudo find ./scripts -type f -exec cp {} /usr/local/bin/ -vf ';'
exit '0'
