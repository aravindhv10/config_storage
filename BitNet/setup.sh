#!/bin/sh
cd "$('dirname' '--' "${0}")"
'python3' '-m' 'venv' './venv'

. './venv/bin/activate'

'pip3' 'install' '--upgrade' \
    'pip' \
    'wheel' \
;

. './venv/bin/activate'

'pip3' 'install' \
    '--index-url' 'https://download.pytorch.org/whl/cpu' \
    'torch' \
    'torchvision' \
    'torchaudio' \
;

. './venv/bin/activate'

'pip3' 'install' \
    'accelerate' \
;

. './venv/bin/activate'

'pip3' 'install' \
    'git+https://github.com/huggingface/transformers.git@refs/pull/33410/head' \
;
