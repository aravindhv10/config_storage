. "${HOME}/.shrc"

get_path > "/tmp/init_${$}"
. "/tmp/init_${$}"

get_nebius_path > "/tmp/init_${$}"
. "/tmp/init_${$}"

all_init_convenience () {

atuin init zsh --disable-up-arrow

}

do_all_init_convenience () {
    all_init_convenience > "${1}"
    . "${1}"
    rm -f -- "${1}"
}

do_all_init_convenience "/tmp/init_${$}"
