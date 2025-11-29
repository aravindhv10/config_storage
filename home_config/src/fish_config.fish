
export SHELL=fish
. "$HOME/.shrc"
atuin init fish | source
source (starship init fish --print-full-init | psub)

fish_vi_key_bindings

function ls
    eza -g $argv
end

function cat
    bat $argv
end
