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
        '494ddf67a104d5deb49380968ecccd8648ee0d7a3e61a8fa45b4dfd3bdc51ba8777922ed0e1864bf81ba78ce718bd40c55c1835c328df3cd1cd0d17312411460' \
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
        'https://ziglang.org/builds/zig-aarch64-linux-0.17.0-dev.2131+d08989840.tar.xz' \
        'zig-aarch64-linux-0.17.0-dev.2131+d08989840.tar.xz' \
        'dc816d391b4a81f5c34a70466716678374b696eadabdf766e13b78b79e931a3c8345f7bfb86cd0db607f5980a8a283dbfd9086f6542fad9d43a8180f2e7a1933' \
        "${HOME}/ZIG/zig-aarch64-linux-0.17.0-dev.2131+d08989840.tar.xz" \
    && cd "${HOME}/ZIG/" \
    && tar -xf './zig-aarch64-linux-0.17.0-dev.2131+d08989840.tar.xz' \
    && cd './zig-aarch64-linux-0.17.0-dev.2131+d08989840' \
    && mv * /usr/local/bin/ \
    && echo 'DONE Download and install zig' ;

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
        '494ddf67a104d5deb49380968ecccd8648ee0d7a3e61a8fa45b4dfd3bdc51ba8777922ed0e1864bf81ba78ce718bd40c55c1835c328df3cd1cd0d17312411460' \
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
