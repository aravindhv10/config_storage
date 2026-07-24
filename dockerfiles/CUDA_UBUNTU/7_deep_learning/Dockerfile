FROM 6_Common_python_data

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START Quantization, optimization and offloading' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
            'accelerate' \
            'datasets' \
            'deepspeed' \
            'diffusers' \
            'evaluate' \
            'huggingface_hub' \
            'lightning[extra]' \
            'onnxruntime-gpu' \
            'onnxscript' \
            'optimum' \
            'optimum-quanto' \
            'prodigyopt' \
            'timm' \
            'torch_dct' \
            'torchmetrics' \
            'transformers' \
            'ultralytics' \
    && echo 'DONE onnxstuff' ;
