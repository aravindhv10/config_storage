export SHELL=zsh

. "${HOME}/.shrc"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="spaceship"
plugins=(git)
source $ZSH/oh-my-zsh.sh
bindkey -v

all_init_convenience () {

atuin init zsh --disable-up-arrow

starship init zsh

zoxide init zsh

}

do_all_init_convenience () {
    all_init_convenience > "${1}"
    . "${1}"
    rm -f -- "${1}"
}

do_all_init_convenience "/tmp/init_${$}"
