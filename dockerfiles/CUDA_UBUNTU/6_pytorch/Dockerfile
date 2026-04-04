FROM 5_libtorch

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START Quantization, optimization and offloading' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
            "huggingface_hub" \
            "timm" \
            "transformers" \
            'accelerate' \
            'albumentations' \
            'datasets' \
            'deepspeed' \
            'diffusers' \
            'einops' \
            'evaluate' \
            'fastapi[standard]' \
            'fastexcel' \
            'grpcio' \
            'grpcio-tools' \
            'inotify-simple' \
            'ipython' \
            'ipywidgets' \
            'jupyter' \
            'jupyterlab' \
            'lightning[extra]' \
            'matplotlib' \
            'onnxruntime-gpu' \
            'onnxscript' \
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
            'ultralytics' \
            'urllib3' \
            'wandb' \
    && echo 'DONE onnxstuff' ;
