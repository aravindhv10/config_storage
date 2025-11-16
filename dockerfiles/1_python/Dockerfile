FROM debtestrustzshhelix

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get -y update \
    && apt-get install -y \
        'ipython3' \
        'libopencv-dev' \
        'python3-dev' \
        'python3-opencv' \
        'python3-pip' \
        'python3-setuptools' \
        'python3-venv' \
    && echo 'DONE apt-get stuff' ;

RUN \
    echo 'START uv download' \
    && curl -LsSf 'https://astral.sh/uv/install.sh' | sh \
    && cp -vf -- "${HOME}/.local/bin/uv" "${HOME}/.local/bin/uvx" '/usr/local/bin/' \
    && echo 'DONE uv download' ;

RUN uv tool install ruff@latest
RUN cp "${HOME}/.local/bin/ruff" '/usr/local/bin'

RUN uv venv "${HOME}/venv"
ENV PATH='/root/venv/bin:/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
ENV VIRTUAL_ENV="${HOME}/venv"
ENV VIRTUAL_ENV_PROMPT='venv'
