#!/bin/sh
. "${HOME}/important_functions.sh" 

adown \
    'https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_0.gguf' \
    'qwen2.5-coder-3b-instruct-q4_0.gguf' \
    '6655cfc81927ed0c40024365b79a296a7fb4ed87bf594990ecf43f868e6f93c4f47789fc24db87c0bd46553b3accc05e792eac5e712c0f20305732ceb9d8d1de' \
    "${HOME}/MODELS/qwen2.5-coder-3b-instruct-q4_0.gguf" \
;
