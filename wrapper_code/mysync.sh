#!/bin/sh
cd "$('dirname' '--' "${0}")"
'gcc' './mysync.c' '-Ofast' '-mtune=native' '-march=native' '-static' '-o' './mysync.exe'
'mv' '-vf' '--' './mysync.exe' "${HOME}/bin/mysync"
