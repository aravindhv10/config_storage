#!/bin/sh
C(){
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

alejandra './HOME,.config,nixpkgs,config.nix'
C './HOME,.config,nixpkgs,config.nix' "${HOME}/.config/nixpkgs/config.nix"

C './__HOME_,.config,wallpaper.sh' "${HOME}/.config/wallpaper.sh"

# C './HOME,.config,ironbar,config.toml' "${HOME}/.config/ironbar/config.toml"
C './HOME,.config,ironbar,config.corn' "${HOME}/.config/ironbar/config.corn"
C './HOME,.config,ironbar,style.css' "${HOME}/.config/ironbar/style.css"

C './HOME,.config,mako,config' "${HOME}/.config/mako/config"

C './HOME,.wezterm.lua' "${HOME}/.wezterm.lua"

C './HOME,.config,foot,foot.ini' "${HOME}/.config/foot/foot.ini"

C './HOME,.shrc' "${HOME}/.shrc"

C './HOME,.bashrc' "${HOME}/.bashrc"

C './HOME,.zshrc' "${HOME}/.zshrc"

C './HOME,.config,nushell,config.nu' "${HOME}/.config/nushell/config.nu"

C './HOME,.config,fish,config.fish' "${HOME}/.config/fish/config.fish"

GCC './SUDO_ASKPASS.c' "${HOME}/SUDO_ASKPASS"

C 'HOME,.config,alacritty,alacritty.toml' "${HOME}/.config/alacritty/alacritty.toml"

C 'HOME,.config,wayfire.ini' "${HOME}/.config/wayfire.ini"

C './4_HOME_,.config,eww,eww.yuck' "${HOME}/.config/eww/eww.yuck"
C './4_HOME_,.config,eww,eww.scss' "${HOME}/.config/eww/eww.scss"

C 'HOME,.config,helix,config.toml' "${HOME}/.config/helix/config.toml"

C './HOME,.config,waybar,config.jsonc' "${HOME}/.config/waybar/config.jsonc"
