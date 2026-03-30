#!/bin/sh
cd "$('dirname' -- "${0}")"
mkdir -pv -- "${HOME}/k3s"
cd "${HOME}/k3s"
aria2c -c -x16 -j16 'https://get.k3s.io' -o 'k3s.sh'
chmod +x ./k3s.sh
sudo -A ./k3s.sh
