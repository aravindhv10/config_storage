#!/bin/sh
. "${HOME}/important_functions.sh"

cd "$(dirname -- "${0}")"

PATH_ETC="$(realpath './etc')"

adown \
    'https://get.rke2.io' \
    'get_rke2.sh' \
    '49b21b3edd6f2ba87e732aeb6a709668302806efb55a060f64db9f680c97dfe096ecc9ec4f95ecaa30af46042c288c115c1d54b9566e4313b993e147b8c442d4' \
    "${HOME}/RKE2/get_rke2.sh" \
;

cd "${HOME}/RKE2/"

chmod +x get_rke2.sh

./get_rke2.sh

cp -apf "${PATH_ETC}" /

systemctl enable rke2-server.service
systemctl start rke2-server.service

'/var/lib/rancher/rke2/bin/kubectl' 'get' 'nodes' \
    '--kubeconfig' '/etc/rancher/rke2/rke2.yaml' ;

journalctl -u rke2-server -f
