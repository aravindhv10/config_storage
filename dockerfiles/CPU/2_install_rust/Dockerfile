FROM 1_install_packages

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install rust + zig' \
    && . "${HOME}/important_functions.sh" \
    && prepare_rust_zig \
    && echo 'DONE Download and install rust + zig'
