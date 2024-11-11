# FROM pytorch/pytorch:2.3.1-cuda12.1-cudnn8-devel
# FROM pytorch/pytorch:2.3.0-cuda12.1-cudnn8-devel
# FROM pytorch/pytorch:2.3.1-cuda11.8-cudnn8-devel
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 as cuda_deb

ENV HOME='/root'
ENV DEBIAN_FRONTEND='noninteractive'
WORKDIR '/root'

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'Starting apt-get stuff' \
    && apt-get -y update \
    && apt-get install -y \
        aria2 \
        bash \
        build-essential \
        ca-certificates \
        curl \
        git \
        git-lfs \
        libgl1 \
        libglib2.0-0 \
        libsm6 \
        libsndfile1-dev \
        libxext6 \
        libxrender1 \
        neovim \
        python3-dev \
        python3-pip \
    && echo 'Done apt-get stuff' ;

FROM cuda_deb as cuda_deb_uv

RUN \
    echo 'Starting uv download' \
    && curl -LsSf 'https://astral.sh/uv/install.sh' | sh \
    && cp -vf -- "${HOME}/.local/bin/uv" '/usr/local/bin/' \
    && echo 'Done uv download' ;

RUN \
    echo 'starting' \
    && uv venv "${HOME}/venv" \
    && echo 'done' ;

FROM cuda_deb_uv as cuda_deb_uv_pip

RUN \
    echo 'starting' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -U \
        pip \
        setuptools \
        wheel \
    && echo 'done' ;

RUN \
    echo 'starting' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        torch \
        torchao \
        torchaudio \
        torchvision \
    && echo 'done' ;

RUN \
    echo 'starting' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        accelerate \
        deepspeed \
        diffusers \
        einops \
        huggingface-hub \
        inotify-simple \
        ninja \
        optimum-quanto \
        packaging \
        peft \
        prodigyopt \
        sentencepiece \
        transformers \
    && echo 'done' ;

RUN \
    echo 'starting' \
    && . /root/venv/bin/activate \
    && uv pip install \
        accelerate \
        datasets \
        decord \
        deepspeed \
        diffusers \
        einops \
        gekko \
        huggingface-hub \
        inotify-simple \
        ninja \
        optimum-quanto \
        packaging \
        peft \
        prodigyopt \
        protobuf \
        qwen-vl-utils \
        sentencepiece \
        transformers \
    && echo 'done' ;

RUN \
    echo 'starting' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install --no-deps \
        autoawq-kernels \
        auto-gptq \
        autoawq \
        optimum  \
    && echo 'done' ;

RUN \
    echo 'starting' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        jupyterlab \
    && echo 'done' ;

RUN \
    echo 'starting' \
    && cd /root \
    && git clone --depth 1 'https://github.com/huggingface/transformers.git' \
    && cd transformers \
    && . /root/venv/bin/activate \
    && uv pip install -e . \
    && echo 'done' \
;

RUN \
    echo 'starting' \
    && cd /root \
    && git clone --depth 1 'https://github.com/huggingface/diffusers.git' \
    && cd diffusers \
    && . /root/venv/bin/activate \
    && uv pip install -e . \
    && echo 'done' \
;

FROM cuda_deb_uv_pip as cuda_deb_uv_pip_flash

RUN \
    echo 'starting' \
    && . /root/venv/bin/activate \
    && pip3 install \
        flash-attn \
    && echo 'done' ;

RUN \
    echo 'starting' \
    && . /root/venv/bin/activate \
    && uv pip install --no-build-isolation \
        xformers \
    && echo 'done' ;

FROM cuda_deb_uv_pip_flash

EXPOSE 8888/tcp

COPY './docker.start_jupyter_lab.sh' '/root/docker.start_jupyter_lab.sh'

COPY './default_config.yaml' '/root/default_config.yaml'

COPY './docker.infer_qwen.py' '/root/docker.infer_qwen.py'
COPY './docker.infer_qwen.sh' '/root/docker.infer_qwen.sh'

COPY './docker.infer_flux.py' '/root/docker.infer_flux.py'
COPY './docker.infer_flux.sh' '/root/docker.infer_flux.sh'
