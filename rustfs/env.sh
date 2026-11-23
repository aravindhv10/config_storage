#!/bin/sh
HOST='127.0.0.1'
NAME_GUEST='rustfs_container'
NAME_IMAGE='docker.io/rustfs/rustfs:latest-glibc'
PASSWORD_GUEST='7*Bellary'
PORT_GUEST='8100'
PORT_HOST='8100'
USER='cloudphysician'
VOLUME="$('realpath' './data')"
