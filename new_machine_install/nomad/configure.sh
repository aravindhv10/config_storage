#!/bin/sh
cd "$(dirname -- "${0}")"

. "${HOME}/important_functions.sh"

mkdir -pv -- '/etc/consul.d/' '/opt/consul' '/opt/nomad/data' '/opt/nomad/plugins'

systemctl stop nomad
systemctl stop consul

cp -vf -- './etc/nomad.d/nomad.hcl' '/etc/nomad.d/nomad.hcl'

sed "s/#NODE_IP#/${1}/g" './etc/consul.d/consul.hcl' \
    | sed "s/#NODE_NAME#/${2}/g" \
    > '/etc/consul.d/consul.hcl' ;

adown \
    'https://releases.hashicorp.com/nomad-device-nvidia/1.1.0/nomad-device-nvidia_1.1.0_linux_amd64.zip' \
    'nomad-device-nvidia_1.1.0_linux_amd64.zip' \
    '6bfeba3a45a197e29e4ce3ee7448edcd1830761ffb72c1d58811f5a437453614eec586451a9e3673877028e335a34594f2fe115fd6fe73cfd7596ed67436c161' \
    "${HOME}/NOMAD/nomad-device-nvidia_1.1.0_linux_amd64.zip" \
;

cd "${HOME}/NOMAD/"
unzip './nomad-device-nvidia_1.1.0_linux_amd64.zip'
mv './nomad-device-nvidia' '/opt/nomad/plugins'

systemctl start consul
systemctl start nomad

consul members
nomad server members
