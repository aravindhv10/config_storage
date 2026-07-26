#!/bin/sh
adown \
    'https://github.com/huggingface/llm-ls/releases/download/0.5.3/llm-ls-x86_64-unknown-linux-gnu.gz' \
    'llm-ls-x86_64-unknown-linux-gnu.gz' \
    '28496e9b0729e981544c8d6d3f92b4a66cf1627f6ef3c97512b1e1af2b36f8cdcb598c36a72c40cfcdb6fbd65038b3315ae834f380ee44a268cd8d937b86bc1d' \
    "${HOME}/LSP/llm-ls-x86_64-unknown-linux-gnu.gz" \
;

gzip -df "${HOME}/LSP/llm-ls-x86_64-unknown-linux-gnu.gz"

chmod +x "${HOME}/LSP/llm-ls-x86_64-unknown-linux-gnu"

cp -vf -- "${HOME}/LSP/llm-ls-x86_64-unknown-linux-gnu" '/usr/local/bin/llm-ls'
