FROM 1_install_packages

ENV CARGO_HOME="${HOME}/cargo"
ENV RUSTUP_HOME="${HOME}/rustup"
ENV PATH="${HOME}/bin:${CARGO_HOME}/bin:${PATH}"

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install rust' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://sh.rustup.rs' \
        'rustup.rs' \
        'cd9fd64eabc989f19a6a16e9cd2caabe935082e2715b9308150f86d3839c99eb9a7e42a7ef6730c6d956d870638ee89a04dd9e7e14fe243cc165967b7f2918da' \
        "${HOME}/rustup-init.sh" \
    && cd "${HOME}" \
    && chmod +x 'rustup-init.sh' \
    && './rustup-init.sh' '-y' '--no-modify-path' \
    && echo 'DONE Download and install rust'

RUN rustup default stable
RUN rustup component add rust-src
RUN rustup component add rust-analyzer
RUN rustup component add rustfmt

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install zig' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://ziglang.org/builds/zig-x86_64-linux-0.17.0-dev.644+3de725074.tar.xz' \
        'zig-x86_64-linux-0.17.0-dev.644+3de725074.tar.xz' \
        '83124f5f2535e2c30fe41da1f3eb92e98c6687423b9d91e18bc7a7d9a02ac72e10930e41cf948c9f8f0f7d434f34973a38a43f13acf38539fafc705cbba94004' \
        "${HOME}/ZIG/zig-x86_64-linux-0.17.0-dev.644+3de725074.tar.xz" \
    && cd "${HOME}/ZIG/" \
    && tar -xf "./zig-x86_64-linux-0.17.0-dev.644+3de725074.tar.xz" \
    && cd './zig-x86_64-linux-0.17.0-dev.644+3de725074/' \
    && mv * /usr/local/bin/ \
    && echo 'DONE Download and install zig' ;
