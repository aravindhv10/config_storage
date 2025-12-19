FROM 4_python

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START pip' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -U \
        'ipython' \
        'ninja' \
        'packaging' \
        'pip' \
        'psutil' \
        'setuptools' \
        'wheel' \
    && echo 'DONE pip' ;

RUN \
    echo 'START pytorch' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        '--extra-index-url' 'https://download.pytorch.org/whl/cu130' \
            'tensorrt' \
            'torch' \
            'torch-tensorrt' \
            'torchao' \
            'torchvision' \
            'xformers' \
    && echo 'DONE pytorch' ;

ENV LIBTORCH='/root/venv/lib/python3.12/site-packages/torch'
ENV CMAKE_PREFIX_PATH="${LIBTORCH}/share/cmake"
ENV LD_LIBRARY_PATH="${LIBTORCH}/lib:${LD_LIBRARY_PATH}"
