#!/bin/sh
. "${HOME}/important_functions.sh"
cd "$(dirname -- "${0}")"

adown \
    'https://github.com/juicedata/juicefs/releases/download/v1.3.1/juicefs-1.3.1-linux-amd64.tar.gz' \
    'juicefs-1.3.1-linux-amd64.tar.gz' \
    '894e5f921230da803bcadd4469eb11bab2371ee5659b276f6899bc9d77acc1eac8b82ce686d61b67c3d3eaa693523825881023f0823715f81e157340c75fd90a' \
    "${HOME}/JuiceFS/juicefs-1.3.1-linux-amd64.tar.gz" ;


cd "${HOME}/JuiceFS/" ;
tar '-xf' 'juicefs-1.3.1-linux-amd64.tar.gz'
install ./juicefs /usr/local/bin
