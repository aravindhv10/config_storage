fish_vi_key_bindings

set PATH {HOME}/.cargo/bin {$HOME}/bin {$PATH}

export SUDO_ASKPASS={$HOME}/SUDO_ASKPASS

function sudo
    /usr/bin/sudo -A $argv
end

function top
    /usr/bin/htop $argv
end

function puthere
    mysync (cat /tmp/list) ./
end

function mysync
    rsync '-avh' '--progress' $argv
    sync ; sync
end

function ls
lsd $argv
end

function cat
bat $argv
end

function du
dust $argv
end

source (/usr/local/bin/starship init fish --print-full-init | psub)
