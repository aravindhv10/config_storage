#!/bin/sh
cd "$(dirname -- "${0}")"
cp -vf -- './target/libmytorch.so' './target/libmytorch.so.1.0' '/lib/'
cp -vf -- './target/release/video_fft' '/bin/'
exit '0'
