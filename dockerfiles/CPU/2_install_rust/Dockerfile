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
        'cd9fd64eabc989f19a6a16e9cd2caabe935082e2715b9308150f86d3839c99eb9a7e42a7ef6730c6d956d870638ee89a04dd9e7e14fe243cc165967b7f2918da' \
        "${HOME}/rustup-init.sh" \
    && cd "${HOME}" \
    && chmod +x 'rustup-init.sh' \
    && './rustup-init.sh' '-y' '--no-modify-path' \
    && echo 'DONE Download and install rust'

RUN rustup component add rust-src
RUN rustup component add rust-analyzer
RUN rustup component add rustfmt
RUN rustup target add x86_64-unknown-linux-musl

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install zig' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://ziglang.org/builds/zig-x86_64-linux-0.17.0-dev.135+9df02121d.tar.xz' \
        'zig-x86_64-linux-0.17.0-dev.135+9df02121d.tar.xz' \
        'e27651509bc4f7f316d29a8c4dfa459c72fcbe340d0c4aed3bab4d229c46ea3ff33131de1b382d1440b132d5e8fb43a080d950d809bc9d833b619f2728b622eb' \
        "${HOME}/ZIG/zig-x86_64-linux-0.17.0-dev.135+9df02121d.tar.xz" \
    && cd "${HOME}/ZIG/" \
    && tar -xf "./zig-x86_64-linux-0.17.0-dev.135+9df02121d.tar.xz" \
    && cd './zig-x86_64-linux-0.17.0-dev.135+9df02121d/' \
    && mv * /usr/local/bin/ \
    && echo 'DONE Download and install zig' ;
