#!/bin/sh
install_flatpak(){
    which flatpak && return
    if test  "$('whoami')" = 'root'
    then
        apt-get install -y flatpak
    else
        sudo apt-get install -y flatpak
    fi
}

install_aria(){
    if test  "$('whoami')" = 'root'
    then
        apt-get install -y aria2
    else
        sudo apt-get install -y aria2
    fi
}

do_download() {
    which aria2c || install_aria

    test -e "${HOME}/TMP/${2}.aria2" \
        && aria2c -c -x16 -j16 "${1}" -o "${2}" -d "${HOME}/TMP/" ;

    test -e "${HOME}/TMP/${2}" \
        || aria2c -c -x16 -j16 "${1}" -o "${2}" -d "${HOME}/TMP/" ;
}

do_link(){
    mkdir -pv -- "$(dirname -- "${2}")"
    ln -vfs -- "${HOME}/SHA512SUM/${1}" "${2}"
}

adown(){
    mkdir -pv -- "${HOME}/TMP" "${HOME}/SHA512SUM"

    test "${#}" '-ge' '4' && do_link "${3}" "${4}"

    test "${#}" '-ge' '3' && test -e "${HOME}/SHA512SUM/${3}" && return 0

    cd "${HOME}/TMP"

    do_download "${1}" "${2}"

    HASH="$(sha512sum "${2}" | cut -d ' ' -f1)"

    test "${#}" '-ge' '3' && test "${3}" '=' "${HASH}" && mv -vf -- "${2}" "${HOME}/SHA512SUM/${HASH}"

    test "${#}" '-ge' '4' && do_link "${3}" "${4}"
}

get_repo_hf(){
    DIR_BASE="${HOME}/HUGGINGFACE"
    DIR_REPO="$('echo' "${1}" | 'sed' 's@^https://huggingface.co/@@g ; s@/tree/main$@@g')"
    DIR_FULL="${DIR_BASE}/${DIR_REPO}"
    URL="$('echo' "${1}" | 'sed' 's@/tree/main$@@g')"

    mkdir '-pv' '--' "$('dirname' '--' "${DIR_FULL}")"
    cd "$('dirname' '--' "${DIR_FULL}")"
    git clone "${URL}"
    cd "${DIR_FULL}"
    git pull
    git submodule update --recursive --init
}

get_repo(){
    DIR_REPO="${HOME}/GITHUB/$('echo' "${1}" | 'sed' 's/^git@github.com://g ; s@^https://github.com/@@g ; s@.git$@@g' )"
    DIR_BASE="$('dirname' '--' "${DIR_REPO}")"

    mkdir -pv -- "${DIR_BASE}"
    cd "${DIR_BASE}"
    git clone "${1}"
    cd "${DIR_REPO}"

    if test "${#}" '-ge' '2'
    then
        git switch "${2}"
    else
        git switch main
    fi

    git pull
    git submodule update --recursive --init

    if test "${#}" '-ge' '3'
    then
        git checkout "${3}"
    fi
}

install_zsh(){
    if test  "$('whoami')" = 'root'
    then
        apt-get update && apt-get install zsh fonts-firacode zip
    else
        sudo apt-get update && sudo apt-get install zsh fonts-firacode zip
    fi
}

get_ohmyzsh(){
    which zsh || install_zsh
    get_repo 'https://github.com/ohmyzsh/ohmyzsh.git'
    test -d "${HOME}/.oh-my-zsh" && rm -rf "${HOME}/.oh-my-zsh"
    test -L "${HOME}/.oh-my-zsh" || ln -vfs "./GITHUB/ohmyzsh/ohmyzsh" "${HOME}/.oh-my-zsh"
    cp "${HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${HOME}/.zshrc"

    get_repo 'https://github.com/spaceship-prompt/spaceship-prompt.git'
    ln -vfs "${HOME}/GITHUB/spaceship-prompt/spaceship-prompt" "${HOME}/.oh-my-zsh/custom/themes/"
    ln -vfs "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "${HOME}/.oh-my-zsh/custom/themes/spaceship.zsh-theme"
    echo 'ZSH_THEME="spaceship"'  >> "${HOME}/.zshrc"
    echo 'bindkey -v' >> "${HOME}/.zshrc"
}

install_rust(){
    . "${HOME}/.cargo/env"
    which cargo || curl --proto '=https' --tlsv1.2 -sSf 'https://sh.rustup.rs' | sh
    . "${HOME}/.cargo/env"
    cargo install zellij --locked
    cargo install bat --locked
    cargo install lsd --locked
    cargo install du-dust --locked
    cargo install ripgrep --locked
    # cargo install starship --locked
    cd "${HOME}/.cargo/bin"
    sudo cp bat dust exa zellij rg /usr/local/bin
}

setup_zshrc_with_rust(){
    echo '. "${HOME}/.cargo/env"' >> "${HOME}/.zshrc"
    # echo 'eval "$(starship init zsh)"' >> "${HOME}/.zshrc"
    echo 'alias cat=bat' >> "${HOME}/.zshrc"
    echo 'alias ls=lsd' >> "${HOME}/.zshrc"
    echo 'alias du=dust' >> "${HOME}/.zshrc"
}

install_awscli(){
    mkdir -pv -- "${HOME}/AWS_CLI"
    cd "${HOME}/AWS_CLI"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

get_squashfs_tools () {
    mkdir -pv -- '/var/tmp/squashfs/lib64' '/var/tmp/squashfs/bin' '/var/tmp/squashfs/man/man1'
    cp -vn -- '/lib64/ld-linux-x86-64.so.2' '/var/tmp/squashfs/lib64/ld-linux-x86-64.so.2'
    get_repo 'https://github.com/plougher/squashfs-tools.git'
    cd "${HOME}/GITHUB/plougher/squashfs-tools/"
    git checkout .
    cd "./squashfs-tools"
    sd -F 'GZIP_SUPPORT = 1' '# GZIP_SUPPORT = 1' './Makefile'
    sd -F '#ZSTD_SUPPORT = 1' 'ZSTD_SUPPORT = 1' './Makefile'
    sd -F 'COMP_DEFAULT = gzip' 'COMP_DEFAULT = zstd' './Makefile'
    sd -F 'INSTALL_PREFIX = /usr/local' 'INSTALL_PREFIX = /var/tmp/squashfs' './Makefile'
    sd -F 'CFLAGS ?= -O2' 'CFLAGS ?= -O3 -march=x86-64-v3 -mtune=native' './Makefile'
    . '/usr/lib/sdk/llvm19/enable.sh'
    export CC='clang'
    export CXX='clang++'
    export LDFLAGS='-Wl,-rpath=/var/tmp/squashfs/lib64 -Wl,--dynamic-linker=/var/tmp/squashfs/lib64/ld-linux-x86-64.so.2'
    make clean
    make -j4
    make -j4 install
}

get_rust_package(){
    get_repo "${1}"
    . '/usr/lib/sdk/rust-stable/enable.sh'
    . '/usr/lib/sdk/llvm19/enable.sh'
    export CC='clang'
    export CXX='clang++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export LDFLAGS='-Wl,-rpath=/var/tmp/RUST/lib64 -Wl,--dynamic-linker=/var/tmp/RUST/lib64/ld-linux-x86-64.so.2'
    export RUSTFLAGS='-C target-cpu=x86-64-v3 -C link-args=-Wl,-rpath=/var/tmp/RUST/lib64 -C link-args=-Wl,--dynamic-linker=/var/tmp/RUST/lib64/ld-linux-x86-64.so.2'
    mkdir -pv -- '/var/tmp/RUST/lib64/' '/var/tmp/RUST/bin/'
    cp -vn -- '/lib64/ld-linux-x86-64.so.2' '/var/tmp/RUST/lib64/ld-linux-x86-64.so.2'
    DIR_DEST='/var/tmp/RUST/bin/'
    cargo build --release
    mkdir -pv -- "${DIR_DEST}"
    if test "${#}" '-ge' '2'
    then
        shift
        cd 'target/release'
        cp -vf -- ${@} "${DIR_DEST}"
    else
        cd 'target/release'
        find ./ -maxdepth 1 -type f -executable -exec cp -vf -- {} "${DIR_DEST}" ';'
    fi
}

get_helix_editor(){
    get_repo 'https://github.com/helix-editor/helix.git'
    . '/usr/lib/sdk/rust-stable/enable.sh'
    . '/usr/lib/sdk/llvm19/enable.sh'
    export CC='clang'
    export CXX='clang++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export LDFLAGS='-Wl,-rpath=/var/tmp/RUST/lib64 -Wl,--dynamic-linker=/var/tmp/RUST/lib64/ld-linux-x86-64.so.2'
    export RUSTFLAGS='-C target-cpu=x86-64-v3 -C link-args=-Wl,-rpath=/var/tmp/RUST/lib64 -C link-args=-Wl,--dynamic-linker=/var/tmp/RUST/lib64/ld-linux-x86-64.so.2'
    mkdir -pv -- '/var/tmp/RUST/lib64/' '/var/tmp/RUST/bin/'
    cp -vn -- '/lib64/ld-linux-x86-64.so.2' '/var/tmp/RUST/lib64/ld-linux-x86-64.so.2'
    DIR_DEST='/var/tmp/RUST/bin/'
    cargo build --release
    cp -apf ./runtime/ /var/tmp/RUST/bin/
    cd 'target/release'
    find ./ -maxdepth 1 -type f -executable -exec cp -vf -- {} "${DIR_DEST}" ';'
    # cargo install --path helix-term
}

get_rust_packages_standard(){
    get_rust_package 'https://github.com/BurntSushi/ripgrep.git'
    get_rust_package 'https://github.com/ClementTsang/bottom.git'
    get_rust_package 'https://github.com/Wilfred/difftastic.git'
    get_rust_package 'https://github.com/ajeetdsouza/zoxide.git'
    get_rust_package 'https://github.com/alacritty/alacritty.git'
    get_rust_package 'https://github.com/astral-sh/ruff.git'
    get_rust_package 'https://github.com/astral-sh/uv.git'
    get_rust_package 'https://github.com/atuinsh/atuin.git'
    get_rust_package 'https://github.com/bootandy/dust.git'
    get_rust_package 'https://github.com/chmln/sd.git'
    get_rust_package 'https://github.com/denisidoro/navi.git'
    get_rust_package 'https://github.com/fish-shell/fish-shell.git'
    get_rust_package 'https://github.com/helix-editor/helix.git'
    get_rust_package 'https://github.com/konradsz/igrep.git'
    get_rust_package 'https://github.com/lsd-rs/lsd.git'
    get_rust_package 'https://github.com/nushell/nushell.git'
    get_rust_package 'https://github.com/sharkdp/bat.git'
    get_rust_package 'https://github.com/sharkdp/fd.git'
    get_rust_package 'https://github.com/skim-rs/skim.git'
    get_rust_package 'https://github.com/starship/starship.git'
    get_rust_package 'https://github.com/svenstaro/miniserve.git'
    get_rust_package 'https://github.com/sxyazi/yazi.git'
    get_rust_package 'https://github.com/zellij-org/zellij.git'
    get_rust_package 'https://github.com/BurntSushi/xsv.git'
    get_rust_package 'https://github.com/dalance/procs.git'
    get_rust_package 'https://github.com/darakian/ddh.git'
    get_rust_package 'https://github.com/redox-os/ion.git'
    get_rust_package 'https://github.com/SUPERCILEX/fuc.git'
    get_rust_package 'https://github.com/watchexec/watchexec.git'
    get_rust_package 'https://github.com/gblach/reflicate.git'
    get_rust_package 'https://github.com/gblach/imge.git'
    get_rust_package 'https://github.com/your-tools/ruplacer.git'
    get_rust_package 'https://github.com/whitfin/runiq.git'
    get_rust_package 'https://github.com/vishaltelangre/ff.git'
    get_rust_package 'https://github.com/shshemi/tabiew.git'
    get_rust_package 'https://github.com/RaphGL/Tuckr.git'
    get_rust_package 'https://github.com/sharkdp/hyperfine.git'
    get_helix_editor
}

get_tree_sitter () {
    get_rust_package 'https://github.com/tree-sitter/tree-sitter.git'
    cd ../../
    make -j4
    mv libtree-sitter.* /var/tmp/RUST/lib64/
    cd lib
    rm -rf build
    mkdir -pv -- build
    cd build
    cmake ../
    rg '/usr/local' | cut -d ':' -f1 | runiq
    sd '/usr/local' '/var/tmp/RUST' $(rg '/usr/local' | cut -d ':' -f1 | runiq)
    make -j4
    make install
}

get_all_deps(){
    find ./ -type l \
        | sed 's@^@("ldd" "@g ; s@$@")@g' \
        | sh \
        | sed 's@\t@ @g' \
        | grep '=>' \
        | grep ' (0x' \
        | grep ')$' \
        | tr ' ' '\n' \
        | grep '/lib' \
        | sort \
        | uniq \
        | sed 's@^@("cp" "-vn" "@g;s@$@" "./")@g' \
        | sh ;

    find ./ -type f \
        | sed 's@^@("ldd" "@g ; s@$@")@g' \
        | sh \
        | sed 's@\t@ @g' \
        | grep '=>' \
        | grep ' (0x' \
        | grep ')$' \
        | tr ' ' '\n' \
        | grep '/lib' \
        | sort \
        | uniq \
        | sed 's@^@("cp" "-vn" "@g;s@$@" "./")@g' \
        | sh ;
}
