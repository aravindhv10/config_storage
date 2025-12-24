FROM 5_libtorch

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START Download all sources' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/facebookresearch/pytorchvideo.git' \
    && get_repo 'https://github.com/huggingface/diffusers.git' \
    && get_repo 'https://github.com/huggingface/transformers.git' \
    && get_repo 'https://github.com/huggingface/pytorch-image-models.git' \
    && get_repo 'https://github.com/huggingface/huggingface_hub.git' \
    && get_repo 'https://github.com/IDEA-Research/detrex.git' \
    && echo 'START Download all sources' ;

RUN \
    echo 'START Quantization, optimization and offloading' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
            'accelerate' \
            'albumentations' \
            'datasets' \
            'deepspeed' \
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
            -e "${HOME}/GITHUB/facebookresearch/pytorchvideo" \
            -e "${HOME}/GITHUB/huggingface/diffusers" \
            -e "${HOME}/GITHUB/huggingface/huggingface_hub" \
            -e "${HOME}/GITHUB/huggingface/pytorch-image-models" \
            -e "${HOME}/GITHUB/huggingface/transformers" \
    && echo 'DONE onnxstuff' ;

RUN \
    echo 'START Quantization, optimization and offloading' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        '--no-build-isolation' \
            -e "${HOME}/GITHUB/IDEA-Research/detrex" \
            -e "${HOME}/GITHUB/IDEA-Research/detrex/detectron2" \
    && echo 'DONE onnxstuff' ;
