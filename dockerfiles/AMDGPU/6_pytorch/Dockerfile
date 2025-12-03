FROM debtestrustzshhelixpytorch

RUN \
    echo 'START pip' \
    && . "/opt/venv/bin/activate" \
    && uv pip install \
        'ipython' \
        'ninja' \
        'packaging' \
        'pip' \
        'setuptools' \
        'wheel' \
    && echo 'DONE pip' ;

RUN \
    echo 'START pip' \
    && . "/opt/venv/bin/activate" \
    && uv pip install \
        'einops' \
        'timm' \
    && echo 'DONE pip' ;
