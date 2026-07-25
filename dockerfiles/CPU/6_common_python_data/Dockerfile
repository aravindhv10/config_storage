FROM 5_libtorch

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START hashing' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -U \
        'blake3' \
    && echo 'DONE hashing' ;

RUN \
    echo 'START dataframe' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -U \
        'datafusion' \
        'fastexcel' \
        'openpyxl' \
        'pandas' \
        'polars' \
        'python-calamine' \
    && echo 'DONE dataframe' ;

RUN \
    echo 'START others' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -U \
        'fastapi[standard]' \
        'inotify-simple' \
        'ipywidgets' \
        'jupyter' \
        'jupyterlab' \
        'psutil' \
        'requests' \
        'scikit-learn' \
        'tqdm' \
        'urllib3' \
        'wandb' \
    && echo 'DONE others' ;

RUN \
    echo 'START plotting' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -U \
        'matplotlib' \
        'seaborn' \
    && echo 'DONE plotting' ;

RUN \
    echo 'START image and tensor stuff' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'albumentations' \
        'einops' \
        'opencv_contrib_python' \
        'opencv_python' \
        'openvino' \
        'pillow' \
        'safetensors' \
        'sentencepiece' \
    && echo 'DONE image and tensor stuff' ;

RUN \
    echo 'START GRPC stuff' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'grpcio' \
        'grpcio-tools' \
        'protobuf' \
    && echo 'DONE GRPC stuff' ;
