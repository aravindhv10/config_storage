#!/bin/sh
cd "${HOME}"

. "${HOME}/venv/bin/activate"

cp -vf -- \
    "${HOME}/default_config.yaml" \
    "${HOME}/.cache/huggingface/accelerate/default_config.yaml" ;

accelerate launch "${HOME}/docker.infer_flux.py"
