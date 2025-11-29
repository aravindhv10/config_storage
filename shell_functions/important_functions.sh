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

build_rust_package_in_cwd(){
    PKG_NAME="$('basename' "$(realpath .)")"

    export CC='clang'
    export CXX='clang++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export LDFLAGS='-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2'
    export RUSTFLAGS="-C target-cpu=x86-64-v3 -C link-args=-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -C link-args=-Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    mkdir -pv -- "/var/tmp/${PKG_NAME}/lib64/" "/var/tmp/${PKG_NAME}/bin/" "/var/tmp/${PKG_NAME}/exe/"

    cp -vn -- '/lib64/ld-linux-x86-64.so.2' "/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    DIR_DEST="/var/tmp/${PKG_NAME}/bin/"

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

    PKG_NAME="$('basename' "$(realpath .)")"

    export CC='clang'
    export CXX='clang++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export LDFLAGS='-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2'
    export RUSTFLAGS="-C target-cpu=x86-64-v3 -C link-args=-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -C link-args=-Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    mkdir -pv -- "/var/tmp/${PKG_NAME}/lib64/" "/var/tmp/${PKG_NAME}/bin/" "/var/tmp/${PKG_NAME}/exe/"

    cp -vn -- '/lib64/ld-linux-x86-64.so.2' "/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    DIR_DEST="/var/tmp/${PKG_NAME}/bin/"

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

get_deb_mirror(){
    mkdir -pv "${HOME}/GITLAB/aravindhv101"
    cd "${HOME}/GITLAB/aravindhv101"
    git clone 'https://gitlab.com/aravindhv101/deb_mirror.git'
    cd deb_mirror

    PKG_NAME="$('basename' "$(realpath .)")"

    export CC='clang'
    export CXX='clang++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export LDFLAGS='-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2'
    export RUSTFLAGS="-C target-cpu=x86-64-v3 -C link-args=-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -C link-args=-Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    mkdir -pv -- "/var/tmp/${PKG_NAME}/lib64/" "/var/tmp/${PKG_NAME}/bin/" "/var/tmp/${PKG_NAME}/exe/"

    cp -vn -- '/lib64/ld-linux-x86-64.so.2' "/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    DIR_DEST="/var/tmp/${PKG_NAME}/bin/"

    cargo build --release

    cd 'target/release'
    find ./ -maxdepth 1 -type f -executable -exec cp -vf -- {} "${DIR_DEST}" ';'
    mkdir -pv -- "/var/tmp/${PKG_NAME}/exe/"
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

get_helix_evil_editor(){
    get_repo 'https://github.com/usagi-flow/evil-helix.git'

    PKG_NAME="$('basename' "$(realpath .)")"

    . '/usr/lib/sdk/rust-stable/enable.sh'
    . '/usr/lib/sdk/llvm19/enable.sh'

    export CC='clang'
    export CXX='clang++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export LDFLAGS='-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2'
    export RUSTFLAGS="-C target-cpu=x86-64-v3 -C link-args=-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -C link-args=-Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    mkdir -pv -- "/var/tmp/${PKG_NAME}/lib64/" "/var/tmp/${PKG_NAME}/bin/" "/var/tmp/${PKG_NAME}/exe/"

    cp -vn -- '/lib64/ld-linux-x86-64.so.2' "/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    DIR_DEST="/var/tmp/${PKG_NAME}/bin/"

    cargo build --release

    cp -apf -- './runtime' "${DIR_DEST}"
    rm -vrf -- "${DIR_DEST}/runtime/grammars/sources" 

    cd 'target/release'
    find ./ -maxdepth 1 -type f -executable -exec cp -vf -- {} "${DIR_DEST}" ';'
    mkdir -pv -- "/var/tmp/${PKG_NAME}/exe/"
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

    . '/usr/lib/sdk/rust-stable/enable.sh'
    . '/usr/lib/sdk/llvm19/enable.sh'

    export CC='clang'
    export CXX='clang++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export LDFLAGS='-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2'
    export RUSTFLAGS="-C target-cpu=x86-64-v3 -C link-args=-Wl,-rpath=/var/tmp/${PKG_NAME}/lib64 -C link-args=-Wl,--dynamic-linker=/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    mkdir -pv -- "/var/tmp/${PKG_NAME}/lib64/" "/var/tmp/${PKG_NAME}/bin/" "/var/tmp/${PKG_NAME}/exe/"

    cp -vn -- '/lib64/ld-linux-x86-64.so.2' "/var/tmp/${PKG_NAME}/lib64/ld-linux-x86-64.so.2"

    DIR_DEST="/var/tmp/${PKG_NAME}/bin/"

    cargo build --release

    cp -apf -- './runtime' "${DIR_DEST}"
    rm -vrf -- "${DIR_DEST}/runtime/grammars/sources" 

    cd 'target/release'
    find ./ -maxdepth 1 -type f -executable -exec cp -vf -- {} "${DIR_DEST}" ';'
    mkdir -pv -- "/var/tmp/${PKG_NAME}/exe/"
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
    make -j
    make -j install
}

get_tmux () {
    get_repo 'https://github.com/tmux/tmux.git' 'master'
    sudo -A apt install automake libevent-dev yacc libncurses-dev build-essential
    sh './autogen.sh'
    mkdir -pv -- "${HOME}/build/tmux"
    cd "${HOME}/build/tmux"
    export CC='gcc'
    export CXX='g++'
    export CFLAGS='-O3 -march=x86-64-v3 -mtune=native'
    export LDFLAGS='-Wl,-rpath=/var/tmp/tmux/lib64 -Wl,--dynamic-linker=/var/tmp/tmux/lib64/ld-linux-x86-64.so.2'
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

    get_deb_mirror
    get_helix_editor
    get_helix_evil_editor
    get_repo 'https://github.com/chmln/sd.git' ; git checkout 'tags/v1.0.0' ; get_rust_package 'https://github.com/chmln/sd.git'

    get_rust_package 'https://github.com/ajeetdsouza/zoxide.git'
    get_rust_package 'https://github.com/alexpasmantier/television.git'
    get_rust_package 'https://github.com/alacritty/alacritty.git'
    get_rust_package 'https://github.com/astral-sh/ruff.git'
    get_rust_package 'https://github.com/astral-sh/uv.git'
    get_rust_package 'https://github.com/atuinsh/atuin.git'
    get_rust_package 'https://github.com/bootandy/dust.git'
    get_rust_package 'https://github.com/BurntSushi/ripgrep.git'
    get_rust_package 'https://github.com/BurntSushi/xsv.git'
    get_rust_package 'https://github.com/ClementTsang/bottom.git'
    get_rust_package 'https://github.com/dalance/procs.git'
    get_rust_package 'https://github.com/darakian/ddh.git'
    get_rust_package 'https://github.com/denisidoro/navi.git'
    get_rust_package 'https://github.com/eza-community/eza.git'
    get_rust_package 'https://github.com/fish-shell/fish-shell.git'
    get_rust_package 'https://github.com/gblach/imge.git'
    get_rust_package 'https://github.com/gblach/reflicate.git'
    get_rust_package 'https://github.com/gitui-org/gitui.git'
    get_rust_package 'https://github.com/konradsz/igrep.git'
    get_rust_package 'https://github.com/latex-lsp/texlab.git'
    get_rust_package 'https://github.com/lsd-rs/lsd.git'
    get_rust_package 'https://github.com/matheus-git/systemd-manager-tui.git'
    get_rust_package 'https://github.com/nushell/nushell.git'
    get_rust_package 'https://github.com/RaphGL/Tuckr.git'
    get_rust_package 'https://github.com/redox-os/ion.git'
    get_rust_package 'https://github.com/rust-lang/rust-bindgen.git'
    get_rust_package 'https://github.com/sharkdp/bat.git'
    get_rust_package 'https://github.com/sharkdp/fd.git'
    get_rust_package 'https://github.com/sharkdp/hyperfine.git'
    get_rust_package 'https://github.com/shshemi/tabiew.git'
    get_rust_package 'https://github.com/skim-rs/skim.git'
    get_rust_package 'https://github.com/starship/starship.git'
    get_rust_package 'https://github.com/SUPERCILEX/fuc.git'
    get_rust_package 'https://github.com/svenstaro/miniserve.git'
    get_rust_package 'https://github.com/sxyazi/yazi.git'
    get_rust_package 'https://github.com/vishaltelangre/ff.git'
    get_rust_package 'https://github.com/watchexec/watchexec.git'
    get_rust_package 'https://github.com/whitfin/runiq.git'
    get_rust_package 'https://github.com/Wilfred/difftastic.git'
    get_rust_package 'https://github.com/your-tools/ruplacer.git'
    get_rust_package 'https://github.com/zellij-org/zellij.git'

    get_tmux
    get_byobu
    get_squashfs_tools
}

get_all_good_programs_and_config () {
    echo 'START Download and install rust programs' \
    && adown \
        'https://github.com/aravindhv10/config_storage/releases/download/v1.0/out.tar.zst' \
        'out.tar.zst' \
        '1aaba657c6b814ff2a75c1d4ec692c09b5c6c76ed4351fca366e8acf160b568750c7881475b4b01d4e2fa8b6eb7348377176bac9012c24303c088e5c047afde8' \
        '/var/tmp/out.tar.zst' \
    && cd '/var/tmp/' \
    && zstd -dfk --long=30 './out.tar.zst' \
    && tar -xf './out.tar' \
    && mv out/* ./ \
    && rmdir -pv -- out \
    && rm -vf -- './out.tar' './out.tar.zst' \
    && ls /var/tmp/*/install.sh | sh \
    && home_config \
    && echo 'DONE Download and install rust programs'
}
