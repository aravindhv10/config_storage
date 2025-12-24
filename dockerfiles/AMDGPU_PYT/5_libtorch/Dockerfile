FROM 4_python
COPY './important_functions.sh' '/root/important_functions.sh'
ENV LIBTORCH='/opt/venv/lib/python3.13/site-packages/torch'
ENV CMAKE_PREFIX_PATH="${LIBTORCH}/share/cmake"
ENV LD_LIBRARY_PATH="${LIBTORCH}/lib:${LD_LIBRARY_PATH}"

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START pip' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'ipython' \
        'ninja' \
        'packaging' \
        'pip' \
        'psutil' \
        'setuptools' \
        'wheel' \
    && echo 'DONE pip' ;
