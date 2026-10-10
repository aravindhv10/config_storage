FROM 5_libtorch

RUN \
    echo 'START hashing' \
    && . "${VIRTUAL_ENV}/bin/activate" \
    && uv pip install -U \
        'blake3' \
    && echo 'DONE hashing' \
    && echo 'START dataframe' \
    && . "${VIRTUAL_ENV}/bin/activate" \
    && uv pip install -U \
        'datafusion' \
        'fastexcel' \
        'openpyxl' \
        'pandas' \
        'polars' \
        'python-calamine' \
    && echo 'DONE dataframe' \
    && echo 'START lancedb' \
    && . "${VIRTUAL_ENV}/bin/activate" \
    && uv pip install -U \
        'lancedb' \
        'pylance' \
    && echo 'DONE lancedb' \
    && echo 'START others' \
    && . "${VIRTUAL_ENV}/bin/activate" \
    && uv pip install -U \
        'fastapi[standard]' \
        'inotify-simple' \
        'ipywidgets' \
        'jupyter' \
        'jupyterlab' \
        'psutil' \
        'psycopg[binary,pool]' \
        'python-multipart' \
        'ray[serve]' \
        'requests' \
        'scikit-learn' \
        'starlette' \
        'tqdm' \
        'urllib3' \
        'wandb' \
        'zarr' \
    && echo 'DONE others' \
    && echo 'START plotting' \
    && . "${VIRTUAL_ENV}/bin/activate" \
    && uv pip install -U \
        'matplotlib' \
        'seaborn' \
    && echo 'DONE plotting' \
    && echo 'START image and tensor stuff' \
    && . "${VIRTUAL_ENV}/bin/activate" \
    && uv pip install \
        'albumentationsx' \
        'einops' \
        'opencv_contrib_python' \
        'opencv_python' \
        'openvino' \
        'pillow' \
        'safetensors' \
        'sentencepiece' \
    && echo 'DONE image and tensor stuff' \
    && echo 'START GRPC stuff' \
    && . "${VIRTUAL_ENV}/bin/activate" \
    && uv pip install \
        'grpcio' \
        'grpcio-tools' \
        'protobuf' \
    && echo 'DONE GRPC stuff'
