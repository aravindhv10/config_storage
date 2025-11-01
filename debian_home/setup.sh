#!/bin/sh
C(){
    git add "${1}"
    mkdir -pv -- "$('dirname' -- "${2}")"
    rm -vf -- "${2}"
    cp -vf -- "${1}" "${2}"
}

GCC () {
    mkdir -pv -- "$('dirname' -- "${2}")"
    rm -vf -- "${2}"
    gcc -O2 "${1}" -o "${2}"
}

rm -vf "${HOME}/.config/systemd/user/plasma-kwin_wayland.service"

GCC './SUDO_ASKPASS.c' "${HOME}/SUDO_ASKPASS"

C './HOME,.config,ironbar,config.toml' "${HOME}/.config/ironbar/config.toml"
C './HOME,.config,ironbar,style.css' "${HOME}/.config/ironbar/style.css"

C './HOME,.config,mako,config' "${HOME}/.config/mako/config"

C './HOME,.wezterm.lua' "${HOME}/.wezterm.lua"

C './HOME,.config,foot,foot.ini' "${HOME}/.config/foot/foot.ini"

C './HOME,important_functions.sh' "${HOME}/important_functions.sh"

C './HOME,.shrc' "${HOME}/.shrc"

C './HOME,.bashrc' "${HOME}/.bashrc"

C './HOME,.zshrc' "${HOME}/.zshrc"

C './HOME,.config,fish,config.fish' "${HOME}/.config/fish/config.fish"

C './HOME,.config,nushell,config.nu' "${HOME}/.config/nushell/config.nu"

C 'HOME,.config,alacritty,alacritty.toml' "${HOME}/.config/alacritty/alacritty.toml"

C 'HOME,.config,wayfire.ini' "${HOME}/.config/wayfire.ini"

C 'HOME,.config,helix,config.toml' "${HOME}/.config/helix/config.toml"

C './HOME,.config,waybar,config.jsonc' "${HOME}/.config/waybar/config.jsonc"
