FROM 1_install_packages

ENV CARGO_HOME="${HOME}/cargo" \
    RUSTUP_HOME="${HOME}/rustup"

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
    && echo 'DONE Download and install rust' \
    && echo 'START Adding additional rust packages' \
    && rustup default stable \
    && rustup component add rust-src \
    && rustup component add rust-analyzer \
    && rustup component add rustfmt \
    && echo 'DONE Adding additional rust packages' \
    && echo 'START Download and install zig' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://ziglang.org/download/0.17.0/zig-x86_64-linux-0.17.0.tar.xz' \
        'zig-x86_64-linux-0.17.0.tar.xz' \
        '152a876860ee15c8d7b77fe7107638e2739732350e4cfe98b6f2748265294994f78dbbe249367316318353b9d401d5184d34833cd221fffd088354f74f4ec499' \
        "${HOME}/ZIG/zig-x86_64-linux-0.17.0.tar.xz" \
    && cd "${HOME}/ZIG/" \
    && tar -xf './zig-x86_64-linux-0.17.0.tar.xz' \
    && cd './zig-x86_64-linux-0.17.0' \
    && mv * /usr/local/bin/ \
    && echo 'DONE Download and install zig'
