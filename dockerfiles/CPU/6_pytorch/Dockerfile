FROM 5_libtorch

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
    && uv pip install \
        'einops' \
        'timm' \
    && echo 'DONE pip' ;

RUN \
    echo 'START onnxstuff' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'grpcio' \
        'grpcio-tools' \
        'onnxruntime' \
        'onnxscript' \
    && echo 'DONE onnxstuff' ;
