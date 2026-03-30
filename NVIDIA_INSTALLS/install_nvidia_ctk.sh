#!/bin/sh
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo -A gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo -A tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo -A apt-get update
sudo -A apt-get install -y nvidia-container-toolkit

nvidia-ctk --version

sudo -A nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
sudo -A nvidia-ctk runtime configure --runtime=docker

grep "  name:" /etc/cdi/nvidia.yaml

sudo -A systemctl restart docker

sudo -A docker run --rm --runtime=nvidia --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi
