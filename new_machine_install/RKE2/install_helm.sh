#!/bin/sh
. "${HOME}/important_functions.sh"

cd "$(dirname -- "${0}")"

export KUBECONFIG='/etc/rancher/rke2/rke2.yaml'
PATH_ETC="$(realpath './etc')"

echo 'START Install helm' \
&& adown \
    'https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3' \
    'get_helm.sh' \
    'eb40998209a12ed9e99b7f88eaba200f973d41819caccb79d74007633937a1858a10fe74d88cbcf952e8838c89c7afaa08a40fe2a2337660e204fc91d02e237d' \
    "${HOME}/RKE2/get_helm.sh" \
&& chmod 700 "${HOME}/RKE2/get_helm.sh" \
&& "${HOME}/RKE2/get_helm.sh" \
&& echo 'DONE Install helm' ;

echo 'START helm nvidia gpu operator' \
&& helm repo add nvidia 'https://helm.ngc.nvidia.com/nvidia' \
&& helm repo update \
&& echo 'DONE helm nvidia gpu operator' ;

echo 'START Remove existing gpu operator' \
&& helm uninstall \
    'gpu-operator' 'nvidia/gpu-operator' \
    '--wait' \
    '-n' 'gpu-operator' \
&& echo 'DONE Remove existing gpu operator' ;

echo 'START Install the nvidia gpu operator' \
&& helm install \
    'gpu-operator' 'nvidia/gpu-operator' \
    '--wait' \
    '-n' 'gpu-operator' \
    '--create-namespace' \
&& echo 'DONE Install the nvidia gpu operator' ;

echo 'START List and verify the install' \
&& helm list '-n' 'gpu-operator' \
&& echo 'DONE List and verify the install' ;

echo 'START spegel container cache' \
&& helm upgrade \
    '--create-namespace' \
    '--namespace' 'spegel' \
    '--install' 'spegel' 'oci://ghcr.io/spegel-org/helm-charts/spegel' \
&& echo 'DONE spegel container cache' ;
