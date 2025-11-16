FROM debtestrustzshhelix

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get -y update \
    && apt-get install -y \
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
    && cp -vf -- "${HOME}/.local/bin/uv" '/usr/local/bin/' \
    && echo 'DONE uv download' ;

RUN uv tool install ruff@latest
RUN cp "${HOME}/.local/bin/ruff" '/usr/local/bin'
