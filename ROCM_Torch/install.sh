#!/bin/sh
uv venv "${HOME}/torch"
. "${HOME}/torch/bin/activate"

uv pip install -U \
    'pip' \
    'ipython' \
;

pip install \
    '--index-url' 'https://download.pytorch.org/whl/rocm6.2.4' \
    'torch' \
    'torchvision' \
    'torchaudio' \
;

uv pip install -U \
    'qwen_vl_utils' \
    'transformers' \
    'accelerate' \
;

. "${HOME}/important_functions.sh"

get_repo 'https://github.com/huggingface/accelerate.git'

pip install -e .

get_repo 'https://github.com/huggingface/accelerate.git'

pip install -e .
