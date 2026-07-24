FROM 6_Common_python_data

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START timm' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'timm' \
    && echo 'DONE timm' ;

RUN \
    echo 'START onnxstuff' \
    && . "${HOME}/venv/bin/activate" \
    && uv pip install \
        'onnxruntime' \
        'onnxscript' \
    && echo 'DONE onnxstuff' ;
