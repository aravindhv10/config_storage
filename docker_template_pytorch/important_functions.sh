#!/bin/sh
do_download() {
    test -e "${HOME}/TMP/${2}.aria2" \
        && aria2c -c -x16 -j16 "${1}" -o "${2}" -d "${HOME}/TMP/" ;

    test -e "${HOME}/TMP/${2}" \
        || aria2c -c -x16 -j16 "${1}" -o "${2}" -d "${HOME}/TMP/" ;
}

do_link(){
    mkdir -pv -- "$(dirname -- "${2}")"
    ln -vfs -- "${HOME}/SHA512SUM/${1}" "${2}"
}

adown(){
    mkdir -pv -- "${HOME}/TMP" "${HOME}/SHA512SUM"

    test "${#}" '-ge' '4' && do_link "${3}" "${4}"

    test "${#}" '-ge' '3' && test -e "${HOME}/SHA512SUM/${3}" && return 0

    cd "${HOME}/TMP"

    do_download "${1}" "${2}"

    HASH="$(sha512sum "${2}" | cut -d ' ' -f1)"

    test "${#}" '-ge' '3' && test "${3}" '=' "${HASH}" && mv -vf -- "${2}" "${HOME}/SHA512SUM/${HASH}"

    test "${#}" '-ge' '4' && do_link "${3}" "${4}"
}

get_repo_hf(){
    DIR_BASE="${HOME}/HUGGINGFACE"
    DIR_REPO="$('echo' "${1}" | 'sed' 's@^https://huggingface.co/@@g ; s@/tree/main$@@g')"
    DIR_FULL="${DIR_BASE}/${DIR_REPO}"
    URL="$('echo' "${1}" | 'sed' 's@/tree/main$@@g')"

    mkdir '-pv' '--' "$('dirname' '--' "${DIR_FULL}")"
    cd "$('dirname' '--' "${DIR_FULL}")"
    git clone "${URL}"
    cd "${DIR_FULL}"
    git pull
    git submodule update --recursive --init
}

get_repo(){
    DIR_REPO="${HOME}/GITHUB/$('echo' "${1}" | 'sed' 's/^git@github.com://g ; s@^https://github.com/@@g ; s@.git$@@g' )"
    DIR_BASE="$('dirname' '--' "${DIR_REPO}")"

    mkdir -pv -- "${DIR_BASE}"
    cd "${DIR_BASE}"
    git clone "${1}"
    cd "${DIR_REPO}"

    if test "${#}" '-ge' '2'
    then
        git switch "${2}"
    else
        git switch main
    fi

    git pull
    git submodule update --recursive --init

    if test "${#}" '-ge' '3'
    then
        git checkout "${3}"
    fi
}

get_ohmyzsh(){
    get_repo 'https://github.com/ohmyzsh/ohmyzsh.git'
    test -d "${HOME}/.oh-my-zsh" && rm -rf "${HOME}/.oh-my-zsh"
    test -L "${HOME}/.oh-my-zsh" || ln -vfs "./GITHUB/ohmyzsh/ohmyzsh" "${HOME}/.oh-my-zsh"
    cp "${HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${HOME}/.zshrc"
}
