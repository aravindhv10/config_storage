FROM 1_install_packages

COPY './important_functions.sh' '/root/important_functions.sh'

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
        'https://ziglang.org/builds/zig-x86_64-linux-0.17.0-dev.1941+71115f0ab.tar.xz' \
        'zig-x86_64-linux-0.17.0-dev.1941+71115f0ab.tar.xz' \
        'ac0b7866a539299083bb74cf1ae4ecdb90a9e33d81241f61ef5892dc5448211c63fd1f3afc335cba9b0dd3557d39adb73d9dd92948e5a37004d3be13a5a4359c' \
        "${HOME}/ZIG/zig-x86_64-linux-0.17.0-dev.1941+71115f0ab.tar.xz" \
    && cd "${HOME}/ZIG/" \
    && tar -xf './zig-x86_64-linux-0.17.0-dev.1941+71115f0ab.tar.xz' \
    && cd './zig-x86_64-linux-0.17.0-dev.1941+71115f0ab' \
    && mv * /usr/local/bin/ \
    && echo 'DONE Download and install zig' ;
