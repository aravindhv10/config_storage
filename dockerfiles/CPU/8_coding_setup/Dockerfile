FROM 7_deep_learning

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install rust programs' \
    && . "${HOME}/important_functions.sh" \
    && get_all_good_programs_and_config \
    && echo 'DONE Download and install rust programs' ;

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START download llm-ls' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://github.com/huggingface/llm-ls/releases/download/0.5.3/llm-ls-x86_64-unknown-linux-gnu.gz' \
        'llm-ls-x86_64-unknown-linux-gnu.gz' \
        '28496e9b0729e981544c8d6d3f92b4a66cf1627f6ef3c97512b1e1af2b36f8cdcb598c36a72c40cfcdb6fbd65038b3315ae834f380ee44a268cd8d937b86bc1d' \
        "${HOME}/LSP/llm-ls-x86_64-unknown-linux-gnu.gz" \
    && gzip -df "${HOME}/LSP/llm-ls-x86_64-unknown-linux-gnu.gz" \
    && chmod +x "${HOME}/LSP/llm-ls-x86_64-unknown-linux-gnu" \
    && mv -vf -- \
        "${HOME}/LSP/llm-ls-x86_64-unknown-linux-gnu" \
        '/usr/local/bin/llm-ls' \
    && echo 'DONE download llm-ls' ;
