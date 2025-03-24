#!/bin/sh
tail -n +5 "${0}" | tr '\n' ' ' > "${0}.slave.sh"
exec sh "${0}.slave.sh" "${1}" "${2}"
exit

mkdir -pv -- "${2}" ;
export INPUT="$(realpath -- "${1}")" ;
export OUTPUT="$(realpath -- "${2}")" ;
cd "$('dirname' '--' "${0}")" ;
. './host.image_names.sh' ;

sudo docker run
--tty
--interactive
--rm
--gpus 'all,"capabilities=compute,utility,video"'
--ipc host
--ulimit memlock=-1
--ulimit stack=67108864
--shm-size 107374182400

--mount 'type=tmpfs,destination=/data/TMPFS,tmpfs-size=137438953472'
-v "${INPUT}:/data/input"
-v "${OUTPUT}:/data/output"

-v "CACHE:/root/.cache"

"${IMAGE_NAME}"

'zsh' ;
