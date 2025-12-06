FROM 1_install_packages

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

RUN rustup component add rust-src
RUN rustup component add rust-analyzer
RUN rustup component add rustfmt
