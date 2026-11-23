#!/bin/sh
HOST='127.0.0.1'
NAME_GUEST='surrealdb_container'
NAME_IMAGE='docker.io/surrealdb/surrealdb:latest'
PASSWORD_GUEST='7*Bellary'
PORT_GUEST='8101'
PORT_HOST='8101'
USER='cloudphysician'
VOLUME="$('realpath' './data')"
