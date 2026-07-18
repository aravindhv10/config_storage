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
        'https://ziglang.org/builds/zig-x86_64-linux-0.17.0-dev.1417+20befa4e6.tar.xz' \
        'zig-x86_64-linux-0.17.0-dev.1417+20befa4e6.tar.xz' \
        '148f7e5e3ec6971d141c3bf2f93cb90285f68d7e391f9b07017c057cd89e187821ea8c97e9a0b53da04f90dc73a9bd748cf24f5f44176b2a1d8c8fdb9d3ed856' \
        "${HOME}/ZIG/zig-x86_64-linux-0.17.0-dev.1417+20befa4e6.tar.xz" \
    && cd "${HOME}/ZIG/" \
    && tar -xf './zig-x86_64-linux-0.17.0-dev.1417+20befa4e6.tar.xz' \
    && cd './zig-x86_64-linux-0.17.0-dev.1417+20befa4e6/' \
    && mv * /usr/local/bin/ \
    && echo 'DONE Download and install zig' ;
