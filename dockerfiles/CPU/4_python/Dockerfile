FROM 3_good_setup

RUN test -e "${HOME}/venv" || uv venv "${HOME}/venv"
ENV PATH="/root/venv/bin:${PATH}"
ENV VIRTUAL_ENV="${HOME}/venv"
ENV VIRTUAL_ENV_PROMPT='venv'
