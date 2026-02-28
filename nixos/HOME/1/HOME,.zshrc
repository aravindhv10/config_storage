export SHELL=zsh

. "${HOME}/.shrc"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="spaceship"
plugins=(battery eza fzf git procs starship systemd uv vi-mode zoxide zsh-interactive-cd)
source $ZSH/oh-my-zsh.sh

all_init_convenience () {

atuin init zsh --disable-up-arrow

}

do_all_init_convenience () {
    all_init_convenience > "${1}"
    . "${1}"
    rm -f -- "${1}"
}

do_all_init_convenience "/tmp/init_${$}"
