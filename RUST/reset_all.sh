#!/bin/sh
slave(){
	cd "${1}"
	git checkout .
	cd ..
}
slave alacritty
slave atuin
slave bat
slave bottom
slave dust
slave fd
slave fish-shell
slave lsd
slave nucleo
slave nushell
slave pylyzer
slave ripgrep
slave ruff
slave skim
slave starship
slave uv
slave yazi
slave zellij
slave zoxide
#exit '0'
