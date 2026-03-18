FROM 2_install_rust

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install rust programs' \
    && . "${HOME}/important_functions.sh" \
    && get_all_good_programs_and_config \
    && echo 'DONE Download and install rust programs' ;


RUN \
    echo 'START Delete tar files after installing' \
    fd '\.tar$' '/var/tmp' -t f -x unlink '{}' \
    echo 'DONE Delete tar files after installing' ;
