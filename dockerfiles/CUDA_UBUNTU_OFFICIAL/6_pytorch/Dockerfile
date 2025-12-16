FROM 5_libtorch

RUN \
    echo 'START pip' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'ipython' \
        'ninja' \
        'packaging' \
        'pip' \
        'psutil' \
        'pyyaml' \
        'safetensors' \
        'setuptools' \
        'wheel' \
    && echo 'DONE pip' ;

RUN \
    echo 'START transformers source install' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/transformers.git' \
    && uv pip install -e . \
    && echo 'DONE transformers source install' ;

RUN \
    echo 'START huggingface-hub source install' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/huggingface_hub.git' \
    && uv pip install -e . \
    && echo 'DONE huggingface-hub source install' ;

RUN \
    echo 'START TIMM install from source' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/pytorch-image-models.git' \
    && uv pip install --no-deps -e . \
    && echo 'DONE TIMM install from source' ;

RUN \
    echo 'START diffusers install from source' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/diffusers.git' \
    && uv pip install -e . \
    && echo 'DONE diffusers install from source' ;

RUN \
    echo 'START Install detectron2 and detrex' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/IDEA-Research/detrex.git' \
    && uv pip install '--no-build-isolation' -e 'detectron2' \
    && uv pip install '--no-build-isolation' -e '.' \
    && echo 'DONE Install detectron2 and detrex' ;

RUN \
    echo 'START onnxstuff' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'grpcio' \
        'grpcio-tools' \
        'onnxruntime-gpu' \
        'onnxscript' \
    && echo 'DONE onnxstuff' ;
