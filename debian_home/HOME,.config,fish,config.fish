export SUDO_ASKPASS={$HOME}/SUDO_ASKPASS

function xs
    cd (fd -t d -t l | sk)
end

abbr --add --position command -- ls lsd
abbr --add --position command -- top btm -b
abbr --add --position command -- cat bat
abbr --add --position command -- du dust

abbr --add --position command -- zz exec zsh

abbr --add --position command -- ac aria2c -c -x16 -j16
abbr --add --position command -- ca aria2c -c -x16 -j16

abbr --add --position command -- qa exec byobu-tmux
abbr --add --position command -- aq exec byobu-tmux

abbr --add --position command -- az exec sudo -A byobu-tmux
abbr --add --position command -- za exec sudo -A byobu-tmux

abbr --add --position command -- ws sudo -A nixos-rebuild switch
abbr --add --position command -- sw sudo -A nixos-rebuild switch

abbr --add --position command -- zc zstd --long=30 -T8 -18
abbr --add --position command -- cz zstd --long=30 -T8 -18

fish_vi_key_bindings

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

atuin init fish --disable-up-arrow > /tmp/$fish_pid.sh
. /tmp/$fish_pid.sh
rm -f -- /tmp/$fish_pid.sh

starship init fish | eval
