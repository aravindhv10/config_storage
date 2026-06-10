FROM 4_python

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START pytorch' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        '--extra-index-url' 'https://download.pytorch.org/whl/cu132' \
            'torch' \
            'torchao' \
            'torchvision' \
            'xformers' \
    && echo 'DONE pytorch' ;

ENV LIBTORCH='/root/venv/lib/python3.12/site-packages/torch'
ENV CMAKE_PREFIX_PATH="${LIBTORCH}/share/cmake"
ENV LD_LIBRARY_PATH="${LIBTORCH}/lib:${LD_LIBRARY_PATH}"
