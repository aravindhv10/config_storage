#!/bin/sh
cd "$(dirname -- "$(realpath -- "${0}")")/.."
emacsclient -c
