#!/bin/sh
cd "$('dirname' '--' "${0}")"
'gcc' './mysync.c' '-Ofast' '-mtune=native' '-march=native' '-o' './mysync.exe'
