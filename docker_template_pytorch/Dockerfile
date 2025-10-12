FROM nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04

ENV HOME='/root'
ENV DEBIAN_FRONTEND='noninteractive'
ENV NVIDIA_DRIVER_CAPABILITIES='compute,utility,video'
WORKDIR '/root'

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get -y update \
    && apt-get install -y \
        'aria2' \
        'git' \
        'wget' \
        'zsh' \
    && echo 'DONE apt-get stuff' ;

RUN \
    echo 'START ohmyzsh' \
    && git clone 'https://github.com/ohmyzsh/ohmyzsh.git' \
    && ln -vfs "${HOME}/ohmyzsh" "${HOME}/.oh-my-zsh" \
    && cp "${HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${HOME}/.zshrc" \
    && echo 'DONE ohmyzsh' ;

RUN \
    echo 'START ohmyzsh' \
    && aria2c -c 'https://starship.rs/install.sh' \
    && chmod +x './install.sh' \
    && './install.sh' '-y' \
    && echo 'eval "$(starship init zsh)"' >> "${HOME}/.zshrc" \
    && echo 'DONE ohmyzsh' ;

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get -y update \
    && apt-get install -y \
        'bat' \
        'fzf' \
        'lsd' \
    && echo 'alias ls=lsd' >> "${HOME}/.zshrc" \
    && echo 'alias cat=batcat' >> "${HOME}/.zshrc" \
    && echo 'DONE apt-get stuff' ;

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get -y update \
    && apt-get install -y \
        'aria2' \
        'build-essential' \
        'cmake' \
        'curl' \
        'ffmpeg' \
        'git' \
        'git-lfs' \
        'ipython3' \
        'libcairo2-dev' \
        'lsd' \
        'make' \
        'neovim' \
        'ninja-build' \
        'pkg-config' \
        'python3-cairo-dev' \
        'python3-dev' \
        'python3-opencv' \
        'python3-pip' \
        'python3-setuptools' \
        'unzip' \
        'wget' \
        'zsh' \
    && echo 'DONE apt-get stuff' ;

RUN \
    echo 'START uv download' \
    && curl -LsSf 'https://astral.sh/uv/install.sh' | sh \
    && cp -vf -- "${HOME}/.local/bin/uv" '/usr/local/bin/' \
    && echo 'DONE uv download' ;

RUN \
    echo 'START venv' \
    && uv venv "${HOME}/venv" \
    && echo 'DONE venv' ;

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
        '--index-url' 'https://download.pytorch.org/whl/cu129' \
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
        '--index-url' 'https://download.pytorch.org/whl/cu129' \
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

COPY ./important_functions.sh '/root/important_functions.sh'

RUN \
    echo 'START transformers source install' \
    && . "${HOME}/important_functions.sh" \
    && install_python_source 'https://github.com/huggingface/transformers.git' \
    && echo 'DONE transformers source install' ;

RUN \
    echo 'START pytorch video source install' \
    && . "${HOME}/important_functions.sh" \
    && install_python_source 'https://github.com/facebookresearch/pytorchvideo.git' \
    && echo 'DONE pytorch video source install' ;

RUN \
    echo 'START diffusers install from source' \
    && . "${HOME}/important_functions.sh" \
    && install_python_source 'https://github.com/huggingface/diffusers.git' \
    && echo 'DONE diffusers install from source' ;

RUN \
    echo 'START TIMM install from source' \
    && . "${HOME}/important_functions.sh" \
    && install_python_source 'https://github.com/huggingface/pytorch-image-models.git' \
    && echo 'DONE TIMM install from source' ;

RUN \
    echo 'START doctr install from source' \
    && . "${HOME}/important_functions.sh" \
    && install_python_source 'https://github.com/mindee/doctr.git' \
    && echo 'DONE doctr install from source' ;

COPY './default_config.yaml' '/root/default_config.yaml'

EXPOSE 8888/tcp

COPY './docker.start_jupyter_lab.sh' '/root/docker.start_jupyter_lab.sh'

RUN \
    echo 'START onnxstuff' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
            'onnxruntime-gpu' \
            'onnxscript' \
    && echo 'DONE onnxstuff' ;

RUN \
    echo 'START flash attn' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
            '--no-build-isolation' \
                'flash-attn' \
    && echo 'DONE flash attn' ;

RUN \
    echo 'START Hub' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
            'huggingface-hub==1.0.0.rc5' \
    && echo 'DONE Hub' ;

ENV PATH='/root/venv/bin:/root/.local/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
ENV VIRTUAL_ENV='/root/venv'
ENV VIRTUAL_ENV_PROMPT='venv'
