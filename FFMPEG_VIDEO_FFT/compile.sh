#!/usr/bin/env bash
# libswscale
# openssl
# libcrypto
# opencv4
# libswresample
# libssl

'gcc' \
    $('pkg-config' '--libs' 'libavcodec,libavutil,libavdevice,libavformat,libavcodec,libavfilter') \
    './main.c' \
;
