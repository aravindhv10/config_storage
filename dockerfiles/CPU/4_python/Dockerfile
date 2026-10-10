FROM 3_good_setup

RUN test -e "${VIRTUAL_ENV}" || uv venv "${VIRTUAL_ENV}"

RUN \
    echo 'START pip' \
    && . "${VIRTUAL_ENV}/bin/activate" \
    && uv pip install -U \
        'ipython' \
        'ninja' \
        'packaging' \
        'pip' \
        'setuptools' \
        'wheel' \
    && echo 'DONE pip'
