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
        'https://ziglang.org/download/0.17.1/zig-x86_64-linux-0.17.1.tar.xz' \
        'zig-x86_64-linux-0.17.1.tar.xz' \
        'b00d74bfb4fd2d01d1a48f2e6a6860f78a79ca26931a61c6f5cdc6c297e34562db63795e0142c280447400eccec57d71e3ba1c03f125e8a9449ba5b4daba366d' \
        "${HOME}/ZIG/zig-x86_64-linux-0.17.1.tar.xz" \
    && cd "${HOME}/ZIG/" \
    && tar -xf './zig-x86_64-linux-0.17.0.tar.xz' \
    && cd './zig-x86_64-linux-0.17.0' \
    && mv * /usr/local/bin/ \
    && echo 'DONE Download and install zig'
