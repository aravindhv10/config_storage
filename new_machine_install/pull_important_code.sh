#!/bin/sh
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
    fi

    git pull
    git submodule update --recursive --init

    if test "${#}" '-ge' '3'
    then
        git checkout "${3}"
    fi
}

get_repo 'https://github.com/aravindhv10/config_storage.git'
get_repo 'git@github.com:cloudphysician-codehub/LOS.git'
