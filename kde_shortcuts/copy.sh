#!/bin/sh
cd "$(dirname -- "${0}")"
mkdir -pv -- "${HOME}/.local/share" "${HOME}/.config"
cp -vf    -- './kglobalshortcutsrc' "${HOME}/.config/"
cp -vapf  -- './applications'       "${HOME}/.local/share"
'../application_shortcut_scripts/copy.sh'
exit '0'
