#!/bin/sh
P_TOUCH () {
    test -e "./${1}" || touch "./${1}"
}

P_GITADD () {
    git add "./${1}"
}

P_CLEAN () {
    rm -vf -- "./${1}"
}

P_READ () {
    cat "./${1}"
}

COMPRESS_FILE_ZSTD () {
    'zstd' "${1}" '--long=30' '-18'
}

DECOMPRESS_FILE_ZSTD () {
    'zstd' "${1}" '--long=30' '-d' '-f'
}

INSTALL_FOLDER () {
    mkdir -pv -- '/usr/local/'
    cp -aspf -- "$('realpath' '--' "${1}/bin")" '/usr/local/'
}

P_PROCESS_PYTHON () {
    expand | grep -v '^ *$' | grep -v '^#!/usr/bin/python3$' | grep -v '^#!/usr/bin/env python3$' | ruff format - 
}

GITADD () {
    P_TOUCH "${1}"
    P_GITADD "${1}"
}

CLEAN () {
    P_CLEAN "${1}"
}

READ_AND_PROCESS_FILE () {
    P_TOUCH "${1}"
    P_READ "${1}" | P_PROCESS_PYTHON
}

READ_ALL_PYTHON(){
    echo '#!/usr/bin/env python3'
    READ_AND_PROCESS_FILE "${1}.config.py"
    READ_AND_PROCESS_FILE "${1}.import.py" | sort | uniq
    READ_AND_PROCESS_FILE "${1}.function.py"
    READ_AND_PROCESS_FILE "${1}.class.py"
    READ_AND_PROCESS_FILE "${1}.execute.py"
}

CLEAN_ALL_PYTHON(){
    P_CLEAN "${1}.config.py"
    P_CLEAN "${1}.import.py"
    P_CLEAN "${1}.function.py"
    P_CLEAN "${1}.class.py"
    P_CLEAN "${1}.execute.py"
}

PREPARE_PYTHON_FILE(){
    echo '#!/usr/bin/env python3' > "./${1}.py"
    READ_ALL_PYTHON "${1}" | P_PROCESS_PYTHON >> "./${1}.py"
    CLEAN_ALL_PYTHON "${1}"
    chmod +x "./${1}.py"
    GITADD "${1}.py"
}

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
        && aria2c --check-certificate=false -c -x16 -j16 "${1}" -o "${2}" -d "${HOME}/TMP/" ;

    test -e "${HOME}/TMP/${2}" \
        || aria2c --check-certificate=false -c -x16 -j16 "${1}" -o "${2}" -d "${HOME}/TMP/" ;
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
}

install_rust(){
    . "${HOME}/.cargo/env"
    which cargo || curl --proto '=https' --tlsv1.2 -sSf 'https://sh.rustup.rs' | sh
}

install_awscli(){
    mkdir -pv -- "${HOME}/AWS_CLI"
    cd "${HOME}/AWS_CLI"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
}

y() {
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
    sd -F '#ZSTD_SUPPORT = 1' 'ZSTD_SUPPORT = 1' './Makefile'
    sd -F 'COMP_DEFAULT = gzip' 'COMP_DEFAULT = zstd' './Makefile'
    sd -F 'INSTALL_PREFIX = /usr/local' 'INSTALL_PREFIX = /var/tmp/squashfs' './Makefile'
    sd -F 'CFLAGS ?= -O2' 'CFLAGS ?= -O3 -march=x86-64-v3 -mtune=native' './Makefile'
    export CC='clang'
    export CXX='clang++'
    export LDFLAGS='-Wl,-rpath=/var/tmp/squashfs/lib64 -Wl,--dynamic-linker=/var/tmp/squashfs/lib64/ld-linux-x86-64.so.2'
    make clean
    make -j
    make -j install
    cd '/var/tmp/squashfs'
    mkdir -pv -- exe
    cd exe
    find '../bin' '../lib64' -type f -exec ln -vfs {} ./ ';'
    get_all_deps
    get_all_deps
    get_all_deps
    get_all_deps
    find ./ -type f -exec mv -vf {} ../lib64/ ';'
    find '../bin' '../lib64' -type f -exec ln -vfs {} ./ ';'
    cd ../lib64/
    mv -vf -- ../bin/lib*.so* ./
}

zigbuild_prepare_rust_package_in_cwd(){
    cargo add mimalloc
    rustup target add x86_64-unknown-linux-musl
}

# zigbuild_rust_package_in_cwd(){
#     export RUSTFLAGS="-C target-cpu=x86-64-v3 -C target-feature=+crt-static"
#     export ZIG_CC_FLAGS="-march=x86-64-v3"
#     rustup target add 'x86_64-unknown-linux-musl'
#     cargo zigbuild '--release' '--target' 'x86_64-unknown-linux-musl'
# }

zigbuild_rust_package_in_cwd(){
    # export RUSTFLAGS="-C target-cpu=x86-64-v3 -C link-self-contained=no"
    export RUSTFLAGS="-C target-cpu=x86-64-v3"
    export ZIG_CC_FLAGS="-march=x86-64-v3"
    rustup target add 'x86_64-unknown-linux-musl'
    cargo zigbuild '--release' '--target' 'x86_64-unknown-linux-musl'
}

build_rust_package_in_cwd(){
    PKG_NAME="$('basename' "$(realpath .)")"

    export CC='clang'
    export CXX='clang++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export LDFLAGS="-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"
    export RUSTFLAGS="-C target-cpu=x86-64-v3 -C link-args=-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -C link-args=-Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    mkdir -pv -- "/var/tmp/${PKG_NAME}/lib64/" "/var/tmp/${PKG_NAME}/bin/" "/var/tmp/${PKG_NAME}/exe/"

    cp -vn -- '/lib64/ld-linux-x86-64.so.2' "/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    DIR_DEST="/var/tmp/${PKG_NAME}/bin/"

    cargo clean
    cargo build --release

    if test "${#}" '-ge' '2'
    then
        shift
        cd 'target/release'
        cp -vf -- ${@} "${DIR_DEST}"
    else
        cd 'target/release'
        find ./ -maxdepth 1 -type f -executable -exec cp -vf -- {} "${DIR_DEST}" ';'
        cd "/var/tmp/${PKG_NAME}/exe/"
        find '../bin' '../lib64' -type f -exec ln -vfs {} ./ ';'
        get_all_deps
        get_all_deps
        get_all_deps
        get_all_deps
        find ./ -type f -exec mv -vf {} ../lib64/ ';'
        find '../bin' '../lib64' -type f -exec ln -vfs {} ./ ';'
        cd ../lib64/
        mv -vf -- ../bin/lib*.so* ./
    fi
}

get_rust_package(){
    get_repo "${1}"
    zigbuild_rust_package_in_cwd
    find './target/x86_64-unknown-linux-musl/release/' -maxdepth 1 -type f -executable -exec cp -vf '{}' '/usr/local/bin/' ';'

    # PKG_NAME="$('basename' "$(realpath .)")"

    # export CC='clang'
    # export CXX='clang++'
    # export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    # export LDFLAGS="-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"
    # export RUSTFLAGS="-C target-cpu=x86-64-v3 -C link-args=-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -C link-args=-Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    # mkdir -pv -- "/var/tmp/${PKG_NAME}/lib64/" "/var/tmp/${PKG_NAME}/bin/" "/var/tmp/${PKG_NAME}/exe/"

    # cp -vn -- '/lib64/ld-linux-x86-64.so.2' "/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    # DIR_DEST="/var/tmp/${PKG_NAME}/bin/"

    # cargo clean
    # cargo build --release

    # if test "${#}" '-ge' '2'
    # then
    #     shift
    #     cd 'target/release'
    #     cp -vf -- ${@} "${DIR_DEST}"
    # else
    #     cd 'target/release'
    #     find ./ -maxdepth 1 -type f -executable -exec cp -vf -- {} "${DIR_DEST}" ';'
    #     cd "/var/tmp/${PKG_NAME}/exe/"
    #     find '../bin' '../lib64' -type f -exec ln -vfs {} ./ ';'
    #     get_all_deps
    #     get_all_deps
    #     get_all_deps
    #     get_all_deps
    #     find ./ -type f -exec mv -vf {} ../lib64/ ';'
    #     find '../bin' '../lib64' -type f -exec ln -vfs {} ./ ';'
    #     cd ../lib64/
    #     mv -vf -- ../bin/lib*.so* ./
    # fi
}

get_helix_evil_editor(){
    get_repo 'https://github.com/usagi-flow/evil-helix.git'

    PKG_NAME="$('basename' "$(realpath .)")"

    export CC='clang'
    export CXX='clang++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export CXXFLAGS="${CFLAGS}"
    export LDFLAGS="-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"
    export RUSTFLAGS="-C target-cpu=x86-64-v3 -C link-args=-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -C link-args=-Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    mkdir -pv -- "/var/tmp/${PKG_NAME}/lib64/" "/var/tmp/${PKG_NAME}/bin/" "/var/tmp/${PKG_NAME}/exe/"

    cp -vn -- '/lib64/ld-linux-x86-64.so.2' "/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    DIR_DEST="/var/tmp/${PKG_NAME}/bin/"

    cargo clean
    cargo build --release

    cp -apf -- './runtime' "${DIR_DEST}"
    rm -vrf -- "${DIR_DEST}/runtime/grammars/sources" 

    cd 'target/release'
    find ./ -maxdepth 1 -type f -executable -exec cp -vf -- {} "${DIR_DEST}" ';'
    cd "/var/tmp/${PKG_NAME}/exe/"
    find '../bin' '../lib64' -type f -exec ln -vfs {} ./ ';'
    get_all_deps
    get_all_deps
    get_all_deps
    get_all_deps
    find ./ -type f -exec mv -vf {} ../lib64/ ';'
    find '../bin' '../lib64' -type f -exec ln -vfs {} ./ ';'
    cd ../lib64/
    mv -vf -- ../bin/lib*.so* ./
}

get_helix_editor(){
    get_repo 'https://github.com/helix-editor/helix.git'

    PKG_NAME="$('basename' "$(realpath .)")"

    export CC='clang'
    export CXX='clang++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export LDFLAGS="-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"
    export RUSTFLAGS="-C target-cpu=x86-64-v3 -C link-args=-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -C link-args=-Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    mkdir -pv -- "/var/tmp/${PKG_NAME}/lib64/" "/var/tmp/${PKG_NAME}/bin/" "/var/tmp/${PKG_NAME}/exe/"

    cp -vn -- '/lib64/ld-linux-x86-64.so.2' "/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    DIR_DEST="/var/tmp/${PKG_NAME}/bin/"

    cargo clean
    cargo build --release

    cp -apf -- './runtime' "${DIR_DEST}"
    rm -vrf -- "${DIR_DEST}/runtime/grammars/sources" 

    cd 'target/release'
    find ./ -maxdepth 1 -type f -executable -exec cp -vf -- {} "${DIR_DEST}" ';'
    cd "/var/tmp/${PKG_NAME}/exe/"
    find '../bin' '../lib64' -type f -exec ln -vfs {} ./ ';'
    get_all_deps
    get_all_deps
    get_all_deps
    get_all_deps
    find ./ -type f -exec mv -vf {} ../lib64/ ';'
    find '../bin' '../lib64' -type f -exec ln -vfs {} ./ ';'
    cd ../lib64/
    mv -vf -- ../bin/lib*.so* ./
}

get_tree_sitter () {
    get_rust_package 'https://github.com/tree-sitter/tree-sitter.git'
    cd "${HOME}/GITHUB/tree-sitter/tree-sitter"
    make -j4
    mv libtree-sitter.* /var/tmp/tree-sitter/
    cd lib
    rm -rf build
    mkdir -pv -- build
    cd build
    cmake ../
    rg '/usr/local' | cut -d ':' -f1 | runiq
    sd '/usr/local' '/var/tmp/tree-sitter' $(rg '/usr/local' | cut -d ':' -f1 | runiq)
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

get_inside_path(){
    export PATH="/usr/lib/sdk/texlive/bin/x86_64-linux:/usr/lib/sdk/texlive/bin:/usr/lib/sdk/llvm19/bin:/usr/lib/sdk/rust-stable/bin:/var/tmp/all/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
}

get_byobu () {
    get_repo 'https://github.com/dustinkirkland/byobu.git' 'master'
    sh './autogen.sh'
    mkdir -pv -- "${HOME}/build/byobu"
    cd "${HOME}/build/byobu"
    export CC='gcc'
    export CXX='g++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export LDFLAGS='-Wl,-rpath=/var/tmp/byobu/lib -Wl,--dynamic-linker=/var/tmp/byobu/lib/ld-linux-x86-64.so.2'
    mkdir -pv -- '/var/tmp/byobu/lib'
    cp -vf -- '/lib64/ld-linux-x86-64.so.2' '/var/tmp/byobu/lib/ld-linux-x86-64.so.2'
    "${HOME}/GITHUB/dustinkirkland/byobu/configure" '--prefix=/var/tmp/byobu'
    make
    make install
}

get_tmux () {
    get_repo 'https://github.com/tmux/tmux.git'
    sudo -A apt install automake libevent-dev yacc libncurses-dev build-essential
    sh './autogen.sh'
    mkdir -pv -- "${HOME}/build/tmux"
    cd "${HOME}/build/tmux"

    # export CC='gcc'
    # export CXX='g++'
    # export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    # export LDFLAGS='-Wl,-rpath=/var/tmp/tmux/lib64 -Wl,--dynamic-linker=/var/tmp/tmux/lib64/ld-linux-x86-64.so.2'
    # export LDFLAGS='-Wl,-rpath=/var/tmp/tmux/lib64 -Wl,--dynamic-linker=/var/tmp/tmux/lib64/ld-linux-x86-64.so.2'

    export CC='zig cc'
    export CXX='zig c++'
    export CFLAGS='-march=x86_64_v3 -static'
    export CXXFLAGS='-march=x86_64_v3 -static'

    mkdir -pv -- '/var/tmp/tmux/lib64'
    cp -vf -- '/lib64/ld-linux-x86-64.so.2' '/var/tmp/tmux/lib64/ld-linux-x86-64.so.2'
    "${HOME}/GITHUB/tmux/tmux/configure" '--prefix=/var/tmp/tmux' '--enable-sixel'
    make -j
    make -j install
    mkdir -pv -- "/var/tmp/tmux/exe/"
    cd "/var/tmp/tmux/exe/"
    find '../bin' '../lib64' -type f -exec ln -vfs {} ./ ';'
    get_all_deps
    get_all_deps
    get_all_deps
    get_all_deps
    find ./ -type f -exec mv -vf {} ../lib64/ ';'
    find '../bin' '../lib64' -type f -exec ln -vfs {} ./ ';'
    cd ../lib64/
    mv -vf -- ../bin/lib*.so* ./
}

get_glibc () {
    get_repo 'https://github.com/bminor/glibc.git' 'master'
    git checkout 'tags/glibc-2.41'
    CONFIGURE="$('realpath' './configure')"
    BUILD_DIR="${HOME}/build/glibc"
    INSTALL_DIR='/var/tmp/glibc'
    rm -rf -- "${BUILD_DIR}"
    mkdir -pv -- "${BUILD_DIR}" "${INSTALL_DIR}"
    cd "${BUILD_DIR}"
    export CC='gcc'
    export CXX='g++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export LDFLAGS=''
    # export CFLAGS=''
    "${CONFIGURE}" "--prefix=${INSTALL_DIR}"
    make -j
    make -j install
}

get_rust_packages_standard(){

    get_repo 'https://github.com/rust-cross/cargo-zigbuild.git'
    cargo build --release
    cp -vf -- './target/release/cargo-zigbuild' '/usr/local/bin/'
    find './target/release/' -maxdepth 1 -type f -executable -exec cp -vf '{}' '/usr/local/bin/' ';'
    get_rust_package 'https://github.com/rust-cross/cargo-zigbuild.git'

    get_helix_evil_editor
    get_helix_editor
    # get_repo 'https://github.com/chmln/sd.git' ; git checkout 'tags/v1.0.0' ; get_rust_package 'https://github.com/chmln/sd.git'

    get_rust_package 'https://github.com/nushell/nushell.git'
    get_rust_package 'https://github.com/BurntSushi/ripgrep.git'
    get_rust_package 'https://github.com/BurntSushi/xsv.git'
    get_rust_package 'https://github.com/Wilfred/difftastic.git'
    get_rust_package 'https://github.com/alexpasmantier/television.git'
    get_rust_package 'https://github.com/aravindhv10/deb_mirror.git'
    get_rust_package 'https://github.com/astral-sh/ruff.git'
    get_rust_package 'https://github.com/astral-sh/uv.git'
    get_rust_package 'https://github.com/ClementTsang/bottom.git'
    get_rust_package 'https://github.com/ajeetdsouza/zoxide.git'
    get_rust_package 'https://github.com/atuinsh/atuin.git'
    get_rust_package 'https://github.com/bootandy/dust.git'
    get_rust_package 'https://github.com/chmln/sd.git'
    get_rust_package 'https://github.com/dalance/procs.git'
    get_rust_package 'https://github.com/eza-community/eza.git'
    get_rust_package 'https://github.com/fish-shell/fish-shell.git'
    get_rust_package 'https://github.com/zellij-org/zellij.git'
    get_rust_package 'https://github.com/shshemi/tabiew.git'
    get_rust_package 'https://github.com/skim-rs/skim.git'
    get_rust_package 'https://github.com/starship/starship.git'
    get_rust_package 'https://github.com/svenstaro/miniserve.git'
    get_rust_package 'https://github.com/sxyazi/yazi.git'
    get_rust_package 'https://github.com/latex-lsp/texlab.git'
    get_rust_package 'https://github.com/gitui-org/gitui.git'
    get_rust_package 'https://github.com/konradsz/igrep.git'
    get_rust_package 'https://github.com/lsd-rs/lsd.git'
    get_rust_package 'https://github.com/matheus-git/systemd-manager-tui.git'
    get_rust_package 'https://github.com/redox-os/ion.git'
    get_rust_package 'https://github.com/sharkdp/bat.git'
    get_rust_package 'https://github.com/sharkdp/fd.git'
    get_rust_package 'https://github.com/sharkdp/hyperfine.git'
    get_rust_package 'https://github.com/vishaltelangre/ff.git'
    get_rust_package 'https://github.com/watchexec/watchexec.git'
    get_rust_package 'https://github.com/whitfin/runiq.git'
    get_rust_package 'https://github.com/your-tools/ruplacer.git'
    get_rust_package 'https://github.com/gblach/imge.git'
    get_rust_package 'https://github.com/gblach/reflicate.git'
    get_rust_package 'https://github.com/RaphGL/Tuckr.git'
    get_rust_package 'https://github.com/SUPERCILEX/fuc.git'
    get_rust_package 'https://github.com/darakian/ddh.git'

    get_rust_package 'https://github.com/denisidoro/navi.git'

    get_rust_package 'https://github.com/rust-lang/rust-bindgen.git'

    get_rust_package 'https://github.com/alacritty/alacritty.git'

    get_repo 'https://github.com/deuxfleurs-org/garage.git' 
    git checkout 'tags/v2.3.0' 
    zigbuild_rust_package_in_cwd
    find './target/x86_64-unknown-linux-musl/release/' -maxdepth 1 -type f -executable -exec cp -vf '{}' '/usr/local/bin/' ';'

    get_tmux
    get_byobu
    get_squashfs_tools
}

INSTALL_ZST_ZRCHIVE () {
    cd '/var/tmp'
    rm -rf "${2}"
    adown \
            "https://github.com/aravindhv10/config_storage/releases/download/v1.1/${2}.tar.zst" \
            "${2}.tar.zst" \
            "${1}" \
            "/var/tmp/${2}.tar.zst" \
    ;
    cd '/var/tmp'
    DECOMPRESS_FILE_ZSTD "${2}.tar.zst"
    tar -xf "${2}.tar"
    INSTALL_FOLDER "${2}"
}

INSTALL_ALL_GOOD_PACKAGES () {
    INSTALL_ZST_ZRCHIVE 'cc2f60f73ebc6b084bdce9991a94c9be674b5fb8dd33dd0723f82574c0dbf9ba089342fc03f0d0eb88be7e6a7248d657c9c94e60ca3e162cf8a670644157dbfb' 'evil-helix'
    INSTALL_ZST_ZRCHIVE '136a6ff183fb606f420a96dd8efcd575b5855d0046bdacf9e1fb07d4aad0d89cd491586471f9de35f4fcf640d1bafdd8bd75b11d4b7b1e1ae540be1ae55216a0' 'STATIC_ZIG_RUST'

    INSTALL_ZST_ZRCHIVE '9a9510486b4bbcff8e77cce627515101e1dca8223d9a80e2f0f60c2a1ada1321d2a39ffddb2f2ce9ce3109637c86fc2e694419a7672092fe3e81b1abed837395' 'helix'
}

get_all_good_programs_and_config () {
    INSTALL_ALL_GOOD_PACKAGES
    cd '/var/tmp/'
    home_config
}

get_amd_rocm_packages_ubuntu() {

# echo 'START install wget' \
# && apt-get update \
# && apt-get install wget \
# && echo 'DONE install wget' ;

# mkdir --parents --mode=0755 /etc/apt/keyrings

# echo 'START get gpg certificate' \
# && wget 'https://repo.radeon.com/rocm/rocm.gpg.key' -O - \
# | gpg --dearmor \
# | tee '/etc/apt/keyrings/rocm.gpg' > /dev/null \
# && echo 'DONE get gpg certificate' ;

# tee /etc/apt/sources.list.d/rocm.list << EOF
# deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/7.1.1 noble main
# deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/graphics/7.1.1/ubuntu noble main
# EOF

# tee /etc/apt/preferences.d/rocm-pin-600 << EOF
# Package: *
# Pin: release o=repo.radeon.com
# Pin-Priority: 600
# EOF

apt update

apt -y install \
    'rocm' \
    'rocm-developer-tools' \
    'rocm-hip-libraries' \
    'rocm-hip-runtime' \
    'rocm-hip-runtime-dev' \
    'rocm-hip-sdk' \
    'rocm-language-runtime' \
    'rocm-ml-libraries' \
    'rocm-ml-sdk' \
    'rocm-opencl-runtime' \
    'rocm-opencl-sdk' \
    'rocm-openmp-sdk' \
;

}

get_apt_packages_on_host() {
    apt update
    apt install \
        'aria2' \
        'automake' \
        'bear' \
        'bison' \
        'build-essential' \
        'clang' \
        'clangd' \
        'clang-format' \
        'clang-tidy' \
        'clang-tools' \
        'cmake' \
        'conntrack' \
        'curl' \
        'elfutils' \
        'ffmpeg' \
        'fish' \
        'fzf' \
        'g++' \
        'gawk' \
        'gcc' \
        'gettext' \
        'gettext-base' \
        'git' \
        'git-lfs' \
        'graphicsmagick-imagemagick-compat' \
        'haproxy' \
        'haproxy-doc' \
        'ipython3' \
        'irqbalance' \
        'jq' \
        'libasound2-dev' \
        'libevent-dev' \
        'libfontconfig-dev' \
        'libgit2-dev' \
        'liblz4-dev' \
        'liblzo2-dev' \
        'libncurses-dev' \
        'libopencv-dev' \
        'libpcre2-16-0' \
        'libpcre2-32-0' \
        'libpcre2-8-0' \
        'libpcre2-dev' \
        'libpcre2-posix3' \
        'libsqlite3-dev' \
        'libssl-dev' \
        'libstdc++-12-dev' \
        'libstdc++-13-dev' \
        'libstdc++-14-dev' \
        'libvulkan1' \
        'libwayland-dev' \
        'libx11-xcb-dev' \
        'libxkbcommon-x11-dev' \
        'libzstd-dev' \
        'make' \
        'mold' \
        'musl-dev' \
        'musl-tools' \
        'mysql-client' \
        'nasm' \
        'neovim' \
        'ninja-build' \
        'pkg-config' \
        'protobuf-compiler' \
        'python3-dev' \
        'python3-newt' \
        'python3-opencv' \
        'python3-pip' \
        'python3-setuptools' \
        'python3-sphinx' \
        'python3-venv' \
        'rclone' \
        'socat' \
        'squashfs-tools' \
        'unzip' \
        'wget' \
        'yacc' \
        'zip' \
        'zsh' \
        'zstd' \
    ;
}

get_apt_packages() {
    apt-get -y install \
        'aria2' \
        'automake' \
        'bear' \
        'bison' \
        'build-essential' \
        'clang' \
        'clangd' \
        'clang-format' \
        'clang-tidy' \
        'clang-tools' \
        'cmake' \
        'curl' \
        'elfutils' \
        'ffmpeg' \
        'fish' \
        'fzf' \
        'g++' \
        'gawk' \
        'gcc' \
        'gettext' \
        'gettext-base' \
        'git' \
        'git-lfs' \
        'graphicsmagick' \
        'gstreamer1.0-libav' \
        'gstreamer1.0-plugins-bad' \
        'gstreamer1.0-plugins-base' \
        'gstreamer1.0-plugins-good' \
        'gstreamer1.0-plugins-ugly' \
        'imagemagick' \
        'ipython3' \
        'jq' \
        'libasound2-dev' \
        'libevent-dev' \
        'libfontconfig-dev' \
        'libgit2-dev' \
        'libgstreamer1.0-dev' \
        'libgstreamer-plugins-bad1.0-dev' \
        'libgstreamer-plugins-base1.0-dev' \
        'liblz4-dev' \
        'liblzo2-dev' \
        'libopencv-dev' \
        'libpcre2-16-0' \
        'libpcre2-32-0' \
        'libpcre2-8-0' \
        'libpcre2-dev' \
        'libpcre2-posix3' \
        'libsqlite3-dev' \
        'libssl-dev' \
        'libstdc++-12-dev' \
        'libstdc++-13-dev' \
        'libstdc++-14-dev' \
        'libvulkan1' \
        'libwayland-dev' \
        'libx11-xcb-dev' \
        'libxkbcommon-x11-dev' \
        'libzstd-dev' \
        'make' \
        'mold' \
        'musl-dev' \
        'musl-tools' \
        'nasm' \
        'neovim' \
        'ninja-build' \
        'pkg-config' \
        'protobuf-compiler' \
        'python3-dev' \
        'python3-newt' \
        'python3-opencv' \
        'python3-pip' \
        'python3-setuptools' \
        'python3-sphinx' \
        'python3-venv' \
        'squashfs-tools' \
        'unzip' \
        'wget' \
        'yacc' \
        'zip' \
        'zsh' \
        'zstd' \
    ; 
}

        # 'libstdc++-10-dev' \

prepare_rust_zig_on_host(){
    export RUSTUP_HOME="${HOME}/rustup"
    export CARGO_HOME="${HOME}/cargo"
    export PATH="${CARGO_HOME}/bin:${HOME}/bin:${PATH}"
    mkdir -pv -- "${HOME}/bin/"

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

    rustup component add rust-src
    rustup component add rust-analyzer
    rustup component add rustfmt
    rustup target add x86_64-unknown-linux-musl

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
}
