FROM 5_libtorch

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START pip' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install -U \
        'ipython' \
        'ninja' \
        'packaging' \
        'pip' \
        'psutil' \
        'setuptools' \
        'wheel' \
    && echo 'DONE pip' ;

        # '--index-url' 'https://download.pytorch.org/whl/cu128' \

RUN \
    echo 'START pytorch' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        '--extra-index-url' 'https://download.pytorch.org/whl/cu128' \
            'torch' \
            'torchao' \
            'torchvision' \
            'xformers' \
    && echo 'DONE pytorch' ;

RUN \
    echo 'START Quantization, optimization and offloading' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'accelerate' \
        'albumentations' \
        'datasets' \
        'deepspeed' \
        'diffusers' \
        'einops' \
        'evaluate' \
        'fastapi[standard]' \
        'fastexcel' \
        'inotify-simple' \
        'ipython' \
        'ipywidgets' \
        'jupyter' \
        'jupyterlab' \
        'lightning[extra]' \
        'matplotlib' \
        'opencv_contrib_python' \
        'opencv_python' \
        'openvino' \
        'optimum' \
        'optimum-quanto' \
        'packaging' \
        'pillow' \
        'prodigyopt' \
        'protobuf' \
        'requests' \
        'safetensors' \
        'scikit-learn' \
        'sentencepiece' \
        'torch_dct' \
        'torchmetrics' \
        'tqdm' \
        'transformers' \
        'ultralytics' \
        'urllib3' \
        'wandb' \
    && echo 'DONE Quantization, optimization and offloading' ;

RUN \
    echo 'START pytorch video source install' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/facebookresearch/pytorchvideo.git' \
    && uv pip install -e . \
    && echo 'DONE pytorch video source install' ;

RUN \
    echo 'START diffusers install from source' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/diffusers.git' \
    && uv pip install -e . \
    && echo 'DONE diffusers install from source' ;

RUN \
    echo 'START transformers source install' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/transformers.git' \
    && uv pip install -e . \
    && echo 'DONE transformers source install' ;

RUN \
    echo 'START TIMM install from source' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/pytorch-image-models.git' \
    && uv pip install -e . \
    && echo 'DONE TIMM install from source' ;

RUN \
    echo 'START huggingface-hub source install' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/huggingface/huggingface_hub.git' \
    && uv pip install -e . \
    && echo 'DONE huggingface-hub source install' ;

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
