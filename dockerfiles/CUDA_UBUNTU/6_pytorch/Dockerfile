FROM debtestrustzshhelixpytorch

RUN \
      --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
      --mount=target=/var/cache/apt,type=cache,sharing=locked \
      echo 'START apt-get stuff' \
      && apt-get -y update \
      && apt-get install -y \
          'aria2' \
          'automake' \
          'bear' \
          'bison' \
          'build-essential' \
          'clang' \
          'cmake' \
          'curl' \
          'gawk' \
          'gettext' \
          'git' \
          'git-lfs' \
          'libevent-dev' \
          'liblz4-dev' \
          'liblzo2-dev' \
          'libpcre2-16-0' \
          'libpcre2-32-0' \
          'libpcre2-8-0' \
          'libpcre2-dev' \
          'libpcre2-posix3' \
          'libssl-dev' \
          'libzstd-dev' \
          'make' \
          'neovim' \
          'ninja-build' \
          'pkg-config' \
          'python3-newt' \
          'python3-sphinx' \
          'squashfs-tools' \
          'unzip' \
          'wget' \
          'yacc' \
          'zip' \
      && echo 'DONE apt-get stuff' ;

RUN \
    echo 'START pip' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -U \
        'ipython' \
        'ninja' \
        'packaging' \
        'pip' \
        'psutil' \
        'setuptools' \
        'wheel' \
    && echo 'DONE pip' ;

RUN \
    echo 'START pytorch' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        '--index-url' 'https://download.pytorch.org/whl/cu128' \
            'torch' \
            'torchao' \
            'torchvision' \
            'xformers' \
    && echo 'DONE pytorch' ;

RUN \
    echo 'START Quantization, optimization and offloading' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'accelerate' \
        'albumentations' \
        'datasets' \
        'deepspeed' \
        'diffusers' \
        'einops' \
        'evaluate' \
        'fastapi[standard]' \
        'fastexcel' \
        'huggingface-hub' \
        'inotify-simple' \
        'ipython' \
        'ipywidgets' \
        'jupyter' \
        'jupyterlab' \
        'lightning[extra]' \
        'matplotlib' \
        'opencv_contrib_python' \
        'opencv_python' \
        'openvino' \
        'optimum' \
        'optimum-quanto' \
        'packaging' \
        'pillow' \
        'prodigyopt' \
        'protobuf' \
        'requests' \
        'safetensors' \
        'scikit-learn' \
        'sentencepiece' \
        'torch_dct' \
        'torchao' \
        'torchmetrics' \
        'tqdm' \
        'transformers' \
        'ultralytics' \
        'urllib3' \
        'wandb' \
    && echo 'DONE Quantization, optimization and offloading' ;

RUN \
    echo 'START transformers source install' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/transformers.git' \
    && uv pip install -e . \
    && echo 'DONE transformers source install' ;

RUN \
    echo 'START pytorch video source install' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/facebookresearch/pytorchvideo.git' \
    && uv pip install -e . \
    && echo 'DONE pytorch video source install' ;

RUN \
    echo 'START diffusers install from source' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/diffusers.git' \
    && uv pip install -e . \
    && echo 'DONE diffusers install from source' ;

RUN \
    echo 'START TIMM install from source' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/pytorch-image-models.git' \
    && uv pip install -e . \
    && echo 'DONE TIMM install from source' ;

RUN \
    echo 'START doctr install from source' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/mindee/doctr.git' \
    && uv pip install -e . \
    && echo 'DONE doctr install from source' ;

RUN \
    echo 'START onnxstuff' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
            'onnxruntime-gpu' \
            'onnxscript' \
    && echo 'DONE onnxstuff' ;

RUN \
    echo 'START Hub' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
            'huggingface-hub' \
    && echo 'DONE Hub' ;
