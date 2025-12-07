FROM 4_python
COPY './important_functions.sh' '/root/important_functions.sh'
ENV CMAKE_PREFIX_PATH='/opt/venv/lib/python3.13/site-packages/torch/share/cmake'
ENV LD_LIBRARY_PATH="/opt/venv/lib/python3.13/site-packages/torch/lib:${LD_LIBRARY_PATH}"
ENV LIBTORCH='/opt/venv/lib/python3.13/site-packages/torch'
