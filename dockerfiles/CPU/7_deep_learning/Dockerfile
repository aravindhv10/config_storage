FROM 6_common_python_data

RUN \
    echo 'START timm' \
    && . "${VIRTUAL_ENV}/bin/activate" \
    && uv pip install \
        'timm' \
    && echo 'DONE timm' \
    && echo 'START onnxstuff' \
    && . "${VIRTUAL_ENV}/bin/activate" \
    && uv pip install \
        'onnxruntime' \
        'onnxscript' \
    && echo 'DONE onnxstuff'
