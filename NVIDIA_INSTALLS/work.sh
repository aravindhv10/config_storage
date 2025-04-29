#!/bin/sh
install_nvidia_drivers(){
    wget 'https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb'
    sudo -A dpkg -i cuda-keyring_1.1-1_all.deb
    sudo -A apt-get update
    sudo -A apt-get -y install cuda-toolkit-12-8
    sudo apt-get install -y nvidia-open
}

install_docker(){
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
    sudo -A apt-get update
    sudo -A apt-get install ca-certificates curl
    sudo -A install -m 0755 -d /etc/apt/keyrings
    sudo -A curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo -A chmod a+r /etc/apt/keyrings/docker.asc
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo -A tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo -A apt-get update
    sudo -A apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo -A docker run hello-world
}

install_nvidia_ctk(){

    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
        && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit

    nvidia-ctk --version

    sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
    sudo nvidia-ctk runtime configure --runtime=docker

    grep "  name:" /etc/cdi/nvidia.yaml

    sudo systemctl restart docker

    sudo docker run --rm --runtime=nvidia --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi
}
