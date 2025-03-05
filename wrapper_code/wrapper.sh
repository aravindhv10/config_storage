#!/bin/sh
cd "$('dirname' '--' "${0}")"
'gcc' './wrapper.c' '-Ofast' '-mtune=native' '-march=native' '-o' './wrapper.exe'
