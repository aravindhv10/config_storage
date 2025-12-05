FROM 4_python

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install libtorch' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://download.pytorch.org/libtorch/rocm6.4/libtorch-shared-with-deps-2.9.1%2Brocm6.4.zip' \
        'libtorch.zip' \
        '0cd40a87997d418dbcd5d2e7550d608b5cd44d241b7409118142311d434c32c247e1a96b80ee9bd7b4cf70c53b8bd43e0bf7078c1cecf07445dfcebf438e6486' \
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
