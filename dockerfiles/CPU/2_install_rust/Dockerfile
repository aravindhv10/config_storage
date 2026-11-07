FROM 1_install_packages

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install rust' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://sh.rustup.rs' \
        'rustup.rs' \
        '8b854962ca5f69032a9bb98317baa2a0b75ae773c351bb6867931eb01b0ce4c5d1778f22a348ed0528a1713de3374c41f00d2bcfcdbdfd7717c07249b7d31828' \
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
