#!/bin/sh
cd "$('dirname' '--' "${0}")"
'gcc' './main.c' '-Ofast' '-mtune=native' '-march=native' '-static' '-o' './main.exe'
'mv' '-vf' '--' './main.exe' "${HOME}/bin/cxx"
