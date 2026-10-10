FROM 6_common_python_data

RUN \
    echo 'START Quantization, optimization and offloading' \
    && . "${VIRTUAL_ENV}/bin/activate" \
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
    && echo 'DONE onnxstuff'
