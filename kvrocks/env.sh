#!/bin/sh
NAME_IMAGE='docker.io/apache/kvrocks'
NAME_GUEST='container_kvrocks'
PORT_GUEST='6666'
PORT_HOST='8102'
VOLUME_GUEST='/var/lib/kvrocks'
VOLUME_HOST="$('realpath' './volume')"
