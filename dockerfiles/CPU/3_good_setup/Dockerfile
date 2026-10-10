FROM 2_install_rust

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install rust programs' \
    && . "${HOME}/important_functions.sh" \
    && get_all_good_programs_and_config \
    && echo 'DONE Download and install rust programs' \
    echo 'START Delete tar files after installing' \
    fd '\.tar$' '/var/tmp' -t f -x unlink '{}' \
    echo 'DONE Delete tar files after installing'
