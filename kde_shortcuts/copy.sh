#!/bin/sh
cd "$(dirname -- "${0}")"
mkdir -pv -- "${HOME}/.local/share" "${HOME}/.config"
cp -vf    -- './kglobalshortcutsrc' "${HOME}/.config/"
cp -vapf  -- './applications'       "${HOME}/.local/share"
find ./scripts/ -type f | grep '^\./scripts/M.*_.*$' | sed 's@^@("cp" "-vf" "--" "@g ; s@$@" "/usr/local/bin/");@g' | sudo sh
exit '0'
