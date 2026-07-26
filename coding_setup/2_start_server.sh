#!/bin/sh
podman run \
    -it --rm \
    --name llama-cpp-openvino \
    --network host \
    -v "/home/llm/everything/MODELS:/MODELS" \
    -e 'GGML_OPENVINO_DEVICE=CPU' \
    'ghcr.io/ggml-org/llama.cpp:full-openvino' \
    --server \
    -m '/MODELS/qwen2.5-coder-3b-instruct-q4_0.gguf' \
    --host 0.0.0.0 \
    --port 8080 \
    -t 4 \
    -c 4096 \
    --embedding \
    --alias qwen3b \
;
