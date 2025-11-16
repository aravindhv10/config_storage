FROM debtestrustzsh

RUN rustup component add rust-src
RUN rustup component add rust-analyzer

RUN aria2c -c -x16 -j16 'https://github.com/helix-editor/helix/releases/download/25.07.1/helix-25.07.1-x86_64-linux.tar.xz'
RUN tar -xf ./helix-25.07.1-x86_64-linux.tar.xz
RUN \
    echo 'Start installing helix' \
        && rm -vf -- 'helix-25.07.1-x86_64-linux.tar.xz' \
        && cd './helix-25.07.1-x86_64-linux/' \
        && mv hx /usr/local/bin \
        && mv runtime /usr/local/bin \
        && mv contrib/completion/hx.bash /usr/share/bash-completion/completions/hx \
        && mv ./contrib/completion/hx.zsh /usr/share/zsh/vendor-completions/_hx \
        && chown 'root:root' '/usr/share/zsh/vendor-completions/_hx' \
        && mv ./contrib/completion/hx.fish /usr/share/fish/completions/hx.fish \
        && cd .. \
        && rm -rf -- './helix-25.07.1-x86_64-linux/' \
    && echo 'Done installing helix' ;
