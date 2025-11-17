#!/bin/sh
cd "$(dirname -- "${0}")"
exec cp -aspf -- "$(realpath ./bin)" '/usr/local/'
