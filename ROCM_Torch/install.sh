#!/bin/sh
uv venv "${HOME}/torch"
. "${HOME}/torch/bin/activate"
uv pip install -U pip
pip install \
    '--index-url' 'https://download.pytorch.org/whl/rocm6.2.4' \
    'torch' \
    'torchvision' \
    'torchaudio' \
;
