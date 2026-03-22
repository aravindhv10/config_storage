#!/bin/sh
cd "$('dirname' -- "${0}")"
ffmpeg \
    "-i" './video.mp4' \
    "-r" '8' \
    "-nostdin" \
    "-f" "rawvideo" \
    "-pix_fmt" "rgb24" \
    "-vf" "scale=1280:720" \
    './video.mp4.raw' \
;
exit '0'
