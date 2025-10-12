#!/bin/sh
cd "$('dirname' '--' "${0}")"
. './host.image_names.sh'
docker_build
