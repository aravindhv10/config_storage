FROM 5_libtorch

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START pip' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'albumentations' \
        'einops' \
        'timm' \
    && echo 'DONE pip' ;

RUN \
    echo 'START GRPC stuff' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'grpcio' \
        'grpcio-tools' \
    && echo 'DONE GRPC stuff' ;

RUN \
    echo 'START onnxstuff' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'onnxruntime' \
        'onnxscript' \
    && echo 'DONE onnxstuff' ;
