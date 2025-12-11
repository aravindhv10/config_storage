FROM nvcr.io/nvidia/pytorch:25.11-py3
RUN python3 -m venv --system-site-packages /root/venv

ENV HOME='/root'
ENV DEBIAN_FRONTEND='noninteractive'
ENV CMAKE_EXPORT_COMPILE_COMMANDS=1
WORKDIR '/root'
USER root

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get update' \
    && apt-get update \
    && apt-get -y install \
        'aria2' \
    && echo 'DONE apt-get update' ;

ENV RUSTUP_HOME='/usr/local/rustup'
ENV CARGO_HOME='/usr/local/cargo'
ENV PATH="/usr/local/cargo/bin:${PATH}"

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install rust' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://sh.rustup.rs' \
        'rustup.rs' \
        'b44833a5cc74448c8ace263bea5499b9dccd0b3b5ad08bbd6c5aafcefe7f421a77d04cdf0e24f1e19de0bf4ff93e170d035665ea10afd3eb228a1633ad13dfaa' \
        "${HOME}/rustup-init.sh" \
    && cd "${HOME}" \
    && chmod +x 'rustup-init.sh' \
    && './rustup-init.sh' '-y' '--no-modify-path' \
    && echo 'DONE Download and install rust'

RUN rustup component add rust-src
RUN rustup component add rust-analyzer
RUN rustup component add rustfmt

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get update' \
    && apt-get update \
    && apt-get -y install \
        'fish' \
        'fzf' \
        'git' \
        'zsh' \
        'zstd' \
    && echo 'DONE apt-get update' ;

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install rust programs' \
    && . "${HOME}/important_functions.sh" \
    && get_all_good_programs_and_config \
    && echo 'DONE Download and install rust programs' ;

ENV PATH="/root/venv/bin:${PATH}"
ENV VIRTUAL_ENV="${HOME}/venv"
ENV VIRTUAL_ENV_PROMPT='venv'

ENV LIBTORCH='/usr/local/lib/python3.12/dist-packages/torch'
ENV CMAKE_PREFIX_PATH="${LIBTORCH}/share/cmake"
ENV LD_LIBRARY_PATH="${LIBTORCH}/lib:${LD_LIBRARY_PATH}"

RUN \
    echo 'START pip' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'ipython' \
        'ninja' \
        'packaging' \
        'pip' \
        'psutil' \
        'pyyaml' \
        'safetensors' \
        'setuptools' \
        'wheel' \
    && echo 'DONE pip' ;

RUN \
    echo 'START transformers source install' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/transformers.git' \
    && uv pip install -e . \
    && echo 'DONE transformers source install' ;

RUN \
    echo 'START huggingface-hub source install' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/huggingface_hub.git' \
    && uv pip install -e . \
    && echo 'DONE huggingface-hub source install' ;

RUN \
    echo 'START TIMM install from source' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/pytorch-image-models.git' \
    && uv pip install --no-deps -e . \
    && echo 'DONE TIMM install from source' ;

RUN \
    echo 'START diffusers install from source' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/diffusers.git' \
    && uv pip install -e . \
    && echo 'DONE diffusers install from source' ;
