FROM 4_python

RUN \
    echo 'START pytorch' \
    && . "${VIRTUAL_ENV}/bin/activate" \
    && uv pip install \
        '--extra-index-url' 'https://download.pytorch.org/whl/rocm7.2' \
            'torch' \
            'torchvision' \
            'torchao' \
            'xformers' \
    && echo 'DONE pytorch' ;

ENV LIBTORCH="${VIRTUAL_ENV}/lib/python3.12/site-packages/torch"

ENV CMAKE_PREFIX_PATH="${LIBTORCH}/share/cmake" \
    LD_LIBRARY_PATH="${LIBTORCH}/lib:${LD_LIBRARY_PATH}"
