FROM debtestrustzshhelixpy

RUN \
    echo 'START pip' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -U \
        'ipython' \
        'ninja' \
        'packaging' \
        'pip' \
        'setuptools' \
        'wheel' \
    && echo 'DONE pip' ;

RUN \
    echo 'START pytorch' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        '--index-url' 'https://download.pytorch.org/whl/cu128' \
            'torch' \
            'torchvision' \
    && echo 'DONE pytorch' ;

RUN \
    echo 'START pytorch quantization and tensorrt' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'einops' \
        'opencv_contrib_python' \
        'opencv_python' \
        'pillow' \
        'torchao' \
    && echo 'DONE pytorch quantization and tensorrt' ;

RUN \
    echo 'START xformers install' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        '--index-url' 'https://download.pytorch.org/whl/cu128' \
            'xformers' \
    && echo 'DONE xformers install' ;

RUN \
    echo 'START Quantization, optimization and offloading' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'accelerate' \
        'albumentations' \
        'datasets' \
        'deepspeed' \
        'diffusers' \
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
        'openvino' \
        'optimum' \
        'optimum-quanto' \
        'packaging' \
        'prodigyopt' \
        'protobuf' \
        'requests' \
        'safetensors' \
        'scikit-learn' \
        'sentencepiece' \
        'torch_dct' \
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
      --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
      --mount=target=/var/cache/apt,type=cache,sharing=locked \
      echo 'START apt-get stuff' \
      && apt-get -y update \
      && apt-get install -y \
          'aria2' \
          'bear' \
          'zip' \
      && echo 'DONE apt-get stuff' ;

RUN aria2c -c -x16 -j16 'https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-2.9.1%2Bcpu.zip'
RUN unzip './libtorch-shared-with-deps-2.9.1+cpu.zip'
RUN rm -vf -- './libtorch-shared-with-deps-2.9.1+cpu.zip'
ENV LIBTORCH="/usr/"
RUN \
    echo 'Install libtorch' \
    && cd libtorch \
    && cd lib \
    && ls | sed 's@^@(cp -vapf -- "@g;s@$@" "/usr/lib/");@g' | sh \
    && cd .. \
    && cd include \
    && ls | sed 's@^@(cp -vapf -- "@g;s@$@" "/usr/include/");@g' | sh \
    && cd .. \
    && cd share/cmake \
    && ls | sed 's@^@(cp -vapf -- "@g;s@$@" "/usr/share/cmake");@g' | sh \
    && cd ../.. \
    && cd .. \
    && echo 'Done Install libtorch' ;
