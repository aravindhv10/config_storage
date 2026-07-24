FROM 3_good_setup

RUN test -e "${HOME}/venv" || uv venv "${HOME}/venv"
ENV PATH="/root/venv/bin:${PATH}"
ENV VIRTUAL_ENV="${HOME}/venv"
ENV VIRTUAL_ENV_PROMPT='venv'

COPY './important_functions.sh' '/root/important_functions.sh'

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
