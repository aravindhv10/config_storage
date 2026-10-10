FROM 4_python

RUN \
    echo 'START pip' \
    && . "${VIRTUAL_ENV}/bin/activate" \
    && uv pip install \
        '--index-url' 'https://download.pytorch.org/whl/cpu' \
            'torch' \
            'torchvision' \
    && echo 'DONE pip'

ENV LIBTORCH="${VIRTUAL_ENV}/lib/python3.14/site-packages/torch/"

ENV CMAKE_PREFIX_PATH="${LIBTORCH}/share/cmake" \
    LD_LIBRARY_PATH="${LIBTORCH}/lib:${LD_LIBRARY_PATH}"
