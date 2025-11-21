FROM debtestrustzshhelixpytorch

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
    echo 'START pip' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -U \
        '--index-url' 'https://download.pytorch.org/whl/cpu' \
            'torch' \
            'torchvision' \
    && echo 'DONE pip' ;

RUN \
    echo 'START pip' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -U \
        'einops' \
        'timm' \
    && echo 'DONE pip' ;
