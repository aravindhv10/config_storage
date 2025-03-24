FROM rust:latest

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
        'bash' \
        'build-essential' \
        'ca-certificates' \
        'cmake' \
        'curl' \
        'ffmpeg' \
        'git' \
        'git-lfs' \
        'ipython3' \
        'libavcodec-dev' \
        'libavdevice-dev' \
        'libavfilter-dev' \
        'libavformat-dev' \
        'libavutil-dev' \
        'libc6' \
        'libc6-dev' \
        'libcairo2-dev' \
        'libffmpeg-nvenc-dev' \
        'libgirepository1.0-dev' \
        'libgl1' \
        'libglib2.0-0' \
        'libgstrtspserver-1.0-dev' \
        'libnuma-dev' \
        'libnuma1' \
        'libopencv-dev' \
        'libpostproc-dev' \
        'libsdl-kitchensink-dev' \
        'libsm6' \
        'libsndfile1-dev' \
        'libswresample-dev' \
        'libswscale-dev' \
        'libtool' \
        'libxext6' \
        'libxrender1' \
        'libxt-dev' \
        'make' \
        'nasm' \
        'neovim' \
        'ninja-build' \
        'pybind11-dev' \
        'python-gi-dev' \
        'python3-dev' \
        'python3-gst-1.0' \
        'python3-opencv' \
        'python3-pip' \
        'python3-pybind11' \
        'python3-setuptools' \
        'unzip' \
        'wget' \
        'yasm' \
    && echo 'DONE apt-get stuff' ;

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START nvidia cuda download' \
    && wget 'https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb' \
    && dpkg -i 'cuda-keyring_1.1-1_all.deb' \
    && apt-get 'update' \
    && apt-get '-y' 'install' \
        'cuda-toolkit-12-6' \
        'cudnn' \
        'cudnn-cuda-12' \
    && echo 'DONE nvidia cuda download' ;

RUN \
    echo 'START uv download' \
    && curl -LsSf 'https://astral.sh/uv/install.sh' | sh \
    && cp -vf -- "${HOME}/.local/bin/uv" '/usr/local/bin/' \
    && echo 'DONE uv download' ;

RUN \
    echo 'START venv' \
    && uv venv \
        "${HOME}/venv" \
    && echo 'DONE venv' ;

RUN \
    echo 'START pip' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -U \
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
        'torch' \
        'torchvision' \
        'torchaudio' \
        '--index-url' 'https://download.pytorch.org/whl/cu126' \
    && echo 'DONE pytorch' ;

RUN \
    echo 'START pytorch quantization and tensorrt' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'torchao' \
        'torch-tensorrt' \
    && echo 'DONE pytorch quantization and tensorrt' ;

RUN \
    echo 'START Tensor manipulation' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'einops' \
    && echo 'DONE Tensor manipulation' ;

RUN \
    echo 'START Extra misc libs' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'opencv_contrib_python' \
        'opencv_python' \
        'pillow' \
    && echo 'DONE Extra misc libs' ;

RUN \
    echo 'START flash attn install using pip' \
    && . "${HOME}/venv/bin/activate" \
    && pip3 install \
        'flash-attn' \
    && echo 'DONE flash attn install using pip' ;

RUN \
    echo 'START xformers install' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'xformers' \
        '--index-url' 'https://download.pytorch.org/whl/cu126' \
    && echo 'DONE xformers install' ;

RUN \
    echo 'START Quantization, optimization and offloading' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'deepspeed' \
        'accelerate' \
        'lightning' \
        'optimum' \
        'optimum-quanto' \
        'prodigyopt' \
    && echo 'DONE Quantization, optimization and offloading' ;

RUN \
    echo 'START Core huggingface libs' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'diffusers' \
        'huggingface-hub' \
        'peft' \
        'safetensors' \
        'transformers' \
    && echo 'DONE Core huggingface libs' ;

RUN \
    echo 'START Extra libraries - 1' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'inotify-simple' \
        'optimum-quanto' \
        'packaging' \
        'sentencepiece' \
    && echo 'DONE Extra libraries - 1' ;

RUN \
    echo 'START Extra libraries - 2' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'albumentations' \
        'datasets' \
        'evaluate' \
        'gekko' \
        'protobuf' \
        'pycairo' \
        'scikit-learn' \
        'ultralytics' \
    && echo 'DONE Extra libraries - 2' ;

RUN \
    echo 'START Extra libraries - 3' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'dlib' \
        'matplotlib' \
        'tqdm' \
        'urllib3' \
    && echo 'DONE Extra libraries - 3' ;

RUN \
    echo 'START video stuff' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'decord' \
        'qwen-vl-utils[decord]==0.0.8' \
    && echo 'DONE video stuff' ;

RUN \
    echo 'START GPTQ quantization libs' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install --no-deps  \
        'auto-gptq' \
    && echo 'DONE GPTQ quantization libs' ;

RUN \
    echo 'START AWQ quantization libs' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install --no-deps --no-build-isolation \
        'autoawq-kernels' \
        'autoawq' \
    && echo 'DONE AWQ quantization libs' ;

RUN \
    echo 'START ONNX related' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'onnx' \
        'onnxconverter-common' \
        'onnxruntime' \
        'onnxruntime-gpu' \
        'onnxscript' \
        'openvino' \
    && echo 'DONE ONNX related' ;

RUN \
    echo 'START jupyter lab install' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'ipywidgets' \
        'jupyterlab' \
        'jupyter' \
        'ipython' \
    && echo 'DONE jupyter lab install' ;

RUN \
    echo 'START polars' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'polars' \
        'fastexcel' \
    && echo 'DONE polars' ;

RUN \
    echo 'START Pandas' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'pandas' \
        'seaborn' \
    && echo 'DONE Pandas' ;

RUN \
    echo 'START transformers source install' \
    && cd "${HOME}" \
    && git clone --depth 1 'https://github.com/huggingface/transformers.git' \
    && cd transformers \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -e . \
    && echo 'DONE transformers source install' ;

RUN \
    echo 'START pytorch video source install' \
    && cd "${HOME}" \
    && git clone --depth 1 'https://github.com/facebookresearch/pytorchvideo.git' \
    && cd 'pytorchvideo' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -e . \
    && echo 'DONE pytorch video source install' ;

RUN \
    echo 'START diffusers install from source' \
    && cd "${HOME}" \
    && git clone --depth 1 'https://github.com/huggingface/diffusers.git' \
    && cd diffusers \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -e . \
    && echo 'DONE diffusers install from source' ;

RUN \
    echo 'START TIMM install from source' \
    && cd "${HOME}" \
    && git clone --depth 1 'https://github.com/huggingface/pytorch-image-models.git' \
    && cd pytorch-image-models \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -e . \
    && echo 'DONE TIMM install from source' ;

RUN \
    echo 'START TIMM install from source' \
    && cd "${HOME}" \
    && git clone --depth 1 'https://github.com/mindee/doctr.git' \
    && cd doctr \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -e . \
    && echo 'DONE TIMM install from source' ;

RUN \
    echo 'START QWEN 2.5 source' \
    && cd "${HOME}" \
    && git clone --depth 1 'https://github.com/QwenLM/Qwen2.5-VL.git' \
    && cd 'Qwen2.5-VL/qwen-vl-utils' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -e . \
    && echo 'DONE QWEN 2.5 source' ;

RUN \
    echo 'START Installing RTMLib' \
    && cd "${HOME}" \
    && git clone --depth 1 'https://github.com/Tau-J/rtmlib.git' \
    && cd 'rtmlib' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -e . \
    && echo 'DONE Installing RTMLib' ;

RUN \
    echo 'START SAM extra deps' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'numpy' \
        'hydra-core' \
        'iopath' \
    && echo 'DONE SAM extra deps' ;

RUN \
    echo 'START' \
    && cd "${HOME}" \
    && git clone --depth 1 'https://github.com/facebookresearch/sam2.git' \
    && cd 'sam2' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -e . \
    && echo 'DONE' ;

RUN \
    echo 'START Linking SHA512SUM' \
    && ln -vfs -- \
        './.cache/SHA512SUM' \
        '/root/SHA512SUM' \
    && echo 'DONE Linking SHA512SUM' ;

COPY ./important_functions.sh '/root/important_functions.sh'

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get zsh stuff' \
    && apt-get -y update \
    && apt-get install -y \
        'zsh' \
    && echo 'DONE apt-get zsh stuff' ;

RUN \
    echo 'START set up oh my zsh' \
    && . "${HOME}/important_functions.sh" \
    && get_ohmyzsh \
    && echo 'DONE set up oh my zsh' ;

COPY './default_config.yaml' '/root/default_config.yaml'

COPY ./docker.download_sam_checkpoints.sh '/root/docker.download_sam_checkpoints.sh'
