FROM 4_python

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START pip' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        '--index-url' 'https://download.pytorch.org/whl/cpu' \
            'torch==2.11.0' \
            'torchvision==0.26.0' \
            'torchaudio==2.11.0' \
    && echo 'DONE pip' ;

ENV LIBTORCH='/root/venv/lib/python3.14/site-packages/torch/'
ENV CMAKE_PREFIX_PATH="${LIBTORCH}/share/cmake"
ENV LD_LIBRARY_PATH="${LIBTORCH}/lib:${LD_LIBRARY_PATH}"
