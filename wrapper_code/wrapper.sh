#!/bin/sh
cd "$('dirname' '--' "${0}")"
'gcc' './wrapper.c' '-Ofast' '-mtune=native' '-march=native' '-static' '-o' './wrapper.exe'
'mv' '-vf' '--' './wrapper.exe' "${HOME}/bin/c_wrapper"
