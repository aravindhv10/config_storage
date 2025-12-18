FROM 4_python

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install libtorch' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://download.pytorch.org/libtorch/cu130/libtorch-shared-with-deps-2.9.1%2Bcu130.zip' \
        'libtorch.zip' \
        'fbd9c8f54d061600b464202b10a7c053f54ee286466dcf3bf890828a2973e5142c2fb382aae3db56ccca6b403e9021f28d9c43e1bae2085811e62aabd7ee34bd' \
        "${HOME}/libtorch.zip" \
    && cd "${HOME}" \
    && unzip './libtorch.zip' \
    && cd libtorch \
    && cd lib \
    && ls | sed 's@^@(cp -vapf -- "@g;s@$@" "/usr/lib/");@g' | sh \
    && cd .. \
    && cd include \
    && ls | sed 's@^@(cp -vapf -- "@g;s@$@" "/usr/include/");@g' | sh \
    && cd .. \
    && cd share/cmake \
    && ls | sed 's@^@(cp -vapf -- "@g;s@$@" "/usr/share/cmake");@g' | sh \
    && cd ../.. \
    && cd .. \
    && echo 'DONE Download and install libtorch' ;

ENV LIBTORCH="/usr/"
