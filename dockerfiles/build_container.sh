#!/bin/sh
cd "$('dirname' -- "${0}")"
ln -vfs '../shell_functions/important_functions.sh' './'
cp './important_functions.sh' "./${1}/"
cd "./${1}/"
IMAGE_NAME="$(basename -- "${1}")"
mkdir -pv -- './build'
H="$(cat './Dockerfile' './important_functions.sh' | sha512sum | cut -d ' ' -f1)"
test -e "./build/${H}" && exit '0'
CMD='sudo -A docker'
which buildah && CMD='buildah'
${CMD} build -t "${IMAGE_NAME}" -f './Dockerfile' . && touch "./build/${H}"
exit '0'
