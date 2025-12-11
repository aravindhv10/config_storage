FROM nvcr.io/nvidia/pytorch:25.11-py3

RUN python3 -m venv --system-site-packages /root/venv

ENV HOME='/root'
ENV DEBIAN_FRONTEND='noninteractive'
ENV CMAKE_EXPORT_COMPILE_COMMANDS=1
WORKDIR '/root'
USER root

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get update' \
    && apt-get update \
    && apt-get -y install \
        'aria2' \
    && echo 'DONE apt-get update' ;

ENV RUSTUP_HOME='/usr/local/rustup'
ENV CARGO_HOME='/usr/local/cargo'
ENV PATH="/usr/local/cargo/bin:${PATH}"

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install rust' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://sh.rustup.rs' \
        'rustup.rs' \
        'b44833a5cc74448c8ace263bea5499b9dccd0b3b5ad08bbd6c5aafcefe7f421a77d04cdf0e24f1e19de0bf4ff93e170d035665ea10afd3eb228a1633ad13dfaa' \
        "${HOME}/rustup-init.sh" \
    && cd "${HOME}" \
    && chmod +x 'rustup-init.sh' \
    && './rustup-init.sh' '-y' '--no-modify-path' \
    && echo 'DONE Download and install rust'

# RUN rustup component add rust-src
# RUN rustup component add rust-analyzer
# RUN rustup component add rustfmt


# RUN \
#     --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
#     --mount=target=/var/cache/apt,type=cache,sharing=locked \
#     echo 'START apt-get update' \
#     && apt-get update \
#     && apt-get -y install \
#         'aria2' \
#         'automake' \
#         'bear' \
#         'bison' \
#         'build-essential' \
#         'cmake' \
#         'curl' \
#         'fish' \
#         'fzf' \
#         'gawk' \
#         'git' \
#         'make' \
#         'zstd' \
#     && echo 'DONE apt-get update' ;

# RUN \
#     --mount=target=/root/SHA512SUM,type=cache \
#     --mount=target=/root/TMP,type=cache \
#     echo 'START Download and install rust programs' \
#     && . "${HOME}/important_functions.sh" \
#     && get_all_good_programs_and_config \
#     && echo 'DONE Download and install rust programs' ;
