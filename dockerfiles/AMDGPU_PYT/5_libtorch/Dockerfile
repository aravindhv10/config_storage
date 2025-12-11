FROM 4_python
COPY './important_functions.sh' '/root/important_functions.sh'
ENV LIBTORCH='/opt/venv/lib/python3.13/site-packages/torch'
ENV CMAKE_PREFIX_PATH="${LIBTORCH}/share/cmake"
ENV LD_LIBRARY_PATH="${LIBTORCH}/lib:${LD_LIBRARY_PATH}"
