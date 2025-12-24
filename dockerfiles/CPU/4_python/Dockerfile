FROM 3_good_setup

RUN test -e "${HOME}/venv" || uv venv "${HOME}/venv"
ENV PATH="/root/venv/bin:${PATH}"
ENV VIRTUAL_ENV="${HOME}/venv"
ENV VIRTUAL_ENV_PROMPT='venv'

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START Download all sources' \
    && . "${HOME}/important_functions.sh" \
    && get_repo 'https://github.com/facebookresearch/pytorchvideo.git' \
    && get_repo 'https://github.com/huggingface/diffusers.git' \
    && get_repo 'https://github.com/huggingface/transformers.git' \
    && git switch - \
    && get_repo 'https://github.com/huggingface/transformers.git' \
    && git checkout 'tags/v4.57.3' \
    && get_repo 'https://github.com/huggingface/pytorch-image-models.git' \
    && get_repo 'https://github.com/huggingface/huggingface_hub.git' \
    && git switch - \
    && get_repo 'https://github.com/huggingface/huggingface_hub.git' \
    && git checkout 'tags/v0.36.0' \
    && get_repo 'https://github.com/IDEA-Research/detrex.git' \
    && echo 'START Download all sources' ;
