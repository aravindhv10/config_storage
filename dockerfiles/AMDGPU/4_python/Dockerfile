FROM debtestrustzshhelix

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get install -y \
        'ipython3' \
        'libopencv-dev' \
        'python3-dev' \
        'python3-opencv' \
        'python3-pip' \
        'python3-setuptools' \
        'python3-venv' \
    && echo 'DONE apt-get stuff' ;

RUN uv venv "/opt/venv"
ENV PATH="/opt/venv/bin:${PATH}"
ENV VIRTUAL_ENV="/opt/venv"
ENV VIRTUAL_ENV_PROMPT='venv'
