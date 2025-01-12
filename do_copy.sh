#!/bin/sh
cd "$(dirname -- "${0}")"

cd 'alacritty_config'
  mkdir -pv -- "${HOME}/.config/alacritty/"
  cp -vf -- './alacritty.toml' "${HOME}/.config/alacritty/alacritty.toml"
cd ..

mkdir -pv -- "${HOME}/.emacs.d"
mysync 'emacs.d' "${HOME}/.emacs.d"

cd 'fish_config'
  mkdir -pv -- "${HOME}/.config/fish/"
  cp -vf -- './config.fish' "${HOME}/.config/fish/config.fish"
  cp -vf -- './SUDO_ASKPASS' "${HOME}/SUDO_ASKPASS"
cd ..
