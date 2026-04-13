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

get_helix_evil_editor(){
    get_repo 'https://github.com/usagi-flow/evil-helix.git'

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

    get_helix_evil_editor
    get_helix_editor
    # get_repo 'https://github.com/chmln/sd.git' ; git checkout 'tags/v1.0.0' ; get_rust_package 'https://github.com/chmln/sd.git'

    get_rust_package 'https://github.com/BurntSushi/ripgrep.git'
    get_rust_package 'https://github.com/BurntSushi/xsv.git'
    get_rust_package 'https://github.com/ClementTsang/bottom.git'
    get_rust_package 'https://github.com/RaphGL/Tuckr.git'
    get_rust_package 'https://github.com/SUPERCILEX/fuc.git'
    get_rust_package 'https://github.com/Wilfred/difftastic.git'
    get_rust_package 'https://github.com/ajeetdsouza/zoxide.git'
    get_rust_package 'https://github.com/alacritty/alacritty.git'
    get_rust_package 'https://github.com/alexpasmantier/television.git'
    get_rust_package 'https://github.com/aravindhv10/deb_mirror.git'
    get_rust_package 'https://github.com/astral-sh/ruff.git'
    get_rust_package 'https://github.com/astral-sh/uv.git'
    get_rust_package 'https://github.com/atuinsh/atuin.git'
    get_rust_package 'https://github.com/bootandy/dust.git'
    get_rust_package 'https://github.com/chmln/sd.git'
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
    get_rust_package 'https://github.com/redox-os/ion.git'
    get_rust_package 'https://github.com/rust-lang/rust-bindgen.git'
    get_rust_package 'https://github.com/sharkdp/bat.git'
    get_rust_package 'https://github.com/sharkdp/fd.git'
    get_rust_package 'https://github.com/sharkdp/hyperfine.git'
    get_rust_package 'https://github.com/shshemi/tabiew.git'
    get_rust_package 'https://github.com/skim-rs/skim.git'
    get_rust_package 'https://github.com/starship/starship.git'
    get_rust_package 'https://github.com/svenstaro/miniserve.git'
    get_rust_package 'https://github.com/sxyazi/yazi.git'
    get_rust_package 'https://github.com/vishaltelangre/ff.git'
    get_rust_package 'https://github.com/watchexec/watchexec.git'
    get_rust_package 'https://github.com/whitfin/runiq.git'
    get_rust_package 'https://github.com/your-tools/ruplacer.git'
    get_rust_package 'https://github.com/zellij-org/zellij.git'

    get_repo 'https://github.com/deuxfleurs-org/garage.git' ; git checkout 'tags/v2.2.0' ; build_rust_package_in_cwd

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
    INSTALL_ZST_ZRCHIVE '01893e011e5cbc47c383cab361021841f266d60f4cbc4f95dccba5f838309ad642454403eaa5e44ef6eaaa7fff8ba7ab1f6685f4f35c39accae00178bd23efef' 'zoxide'
    INSTALL_ZST_ZRCHIVE '0f1acddc9130967384cd07ee4b5fb52b542e79d560931e131bb785571b44cef09f04c7d5365339cffab73de7ddfdf9071accac390d8951209d01aed240123894' 'deb_mirror'
    INSTALL_ZST_ZRCHIVE '2a1ec10e812cc761490e0878057a3d460d9aebbf3ce4c5960a55f6de6db04ff67a4e4a0f939d935a45be84616f96d170533e4ce6d244625e2b0c0ad89b075adc' 'hyperfine'
    INSTALL_ZST_ZRCHIVE '307cc386b0342f50cb8747f1088198736923fdde446e319abede9734e9a677e022d5315a271dff2c74eb12d700f88fe7724a1887619a8db42d825ba338665a4e' 'watchexec'
    INSTALL_ZST_ZRCHIVE '30d71ebedbc0308ce8b3e75f4d99e6bf2ceb12fc1741c5093817473b8aa9cd5981138cb556919f2ac56acedd4673661076389b7c51a793d5d92f4ac14a16ab0b' 'atuin'
    INSTALL_ZST_ZRCHIVE '40f34c52d6dc2cd5f2278bdd5730038d8775e6613cb9cfdded4d07045aef1a0f7c44c1c3faf368ebdae287d6b4fd4a9fd8eb882d31efaf5136734275135a9323' 'yazi'
    INSTALL_ZST_ZRCHIVE '4172772fce14101ff0affe736d2402abece027077c592adb8c30347a8f6a24a20f0971a88e197ce0b85ff4ab8f222a043556fe0318710281de44c572c961af37' 'sd'
    INSTALL_ZST_ZRCHIVE '439f21ea56a9dcd01c9aba16361aecdce7f40088aeaa4683aa63249cbe9ae9b1fae6533f8f5cf823c7e8ea55e1f1a00757cedd247cad21bd257679228dc5f758' 'procs'
    INSTALL_ZST_ZRCHIVE '455bf0f25f70c894e1ef844a7075adead036e113d22eeff423ffbcf11861dbefbb38db825449b885125010a690e5d952239b95e125cc1d3d1ac4df4047ada7b8' 'bat'
    INSTALL_ZST_ZRCHIVE '4e73a476d3afbffc6161bea54bb552df33491eb3f61fea729f4e0758dde5664e63ca4192e9f57bf7aa3d0ad7c3ff49f56b2df50fb689349a7e87c90a2a721d40' 'texlab'
    INSTALL_ZST_ZRCHIVE '4e9f0efc5b45f316ad6725f414f357d5aec57c7208896dbd68c674ed3547b7954932e2059bc17ddd907b7a6026fec7c10d2715662537c932960a0c47b7beec62' 'tmux'
    INSTALL_ZST_ZRCHIVE '58b44fd80d3a6a485e487d8124c51445dc2247f54a05a2f2931aa8224a779aa5865b8636d206461fcb852dd0ce04b4ba8f441aec866a9e5f81feb5d22cee70e2' 'igrep'
    INSTALL_ZST_ZRCHIVE '59d5f005ec0d11dbe5b4b690703d7abcf87f482cfb42eaa3268de82d70d80629dc50964091c3dd15cc13b36dc3c273c9c07a712078b7fe5174ebf8f607ebfbcf' 'rust-bindgen'
    INSTALL_ZST_ZRCHIVE '5c5fb6af56f319134600288890ebada9e59301aeb19b07a72e516bb44c54fe7fc855baf6605b17b61567a3fd8ab6f3bf322d7da095886bfdddf8516207ecf869' 'Tuckr'
    INSTALL_ZST_ZRCHIVE '5e335b48650bb13008ee120fe82e8afcad3e9d0f8d33f2cbe9b7924094ecaa88c0f7319c2b2d32f519674aa5388b5a8a54cce80e92fbc51e7966d4c70aa9ab41' 'lsd'
    INSTALL_ZST_ZRCHIVE '6546593671b3b81d01b07dbf9d014acd15589679a57e9624cc49dc55540ccce243cae05d723dc7865522e0b4cdfa9a5661c962d7c0a767d88d4dd10e21f61b64' 'imge'
    INSTALL_ZST_ZRCHIVE '7cb8070019fe64253d4ef6417dfd4a3e073ffe22eb1bd12726a3bed222a5a183737aedc0f5ca1af1c553a0c4f6d1ed7b6cb02ca30712e2609befa51ad2fa57a4' 'helix'
    INSTALL_ZST_ZRCHIVE '8b0f4a8440f47465f5f4b144f049b7f3a3b1c3f6070288b53736f99f02775e71d1a5040f7d054bbd1d50e23a8bec474a70c115b2f6b17322a081bbc845b9439e' 'eza'
    INSTALL_ZST_ZRCHIVE '90106dd7a1a032a50934d7d244a79d626a33aa963f15c791fbc3439d2c45e1a9cbea410e035f29a8420ae6753882a8be2e0506b76d0207fbd7fb819a191dc9da' 'fd'
    INSTALL_ZST_ZRCHIVE '930c5e8d81c3cb881cdbf9b1fd70a4d74eb616a3812a875689edf346e6f52dcd9e4444891553a5ca1250faf45a43836fc6c70554c7954c6ec75c16b71e124cf3' 'nushell'
    INSTALL_ZST_ZRCHIVE '956a087e43f021dca59b9f43c1a2e7f83071145dadf9657e5421316cfcd03bcf328f3136b2da024e1f8db6e735b140613ea0f08e6651245ad134e8d49aa4aedf' 'tabiew'
    INSTALL_ZST_ZRCHIVE '979b06d17ec79f4fdb1dfb849953fa7d061b38ee2b83eb44e427145cdcb2808830c09678f742c8dfadbbdf581db0ddab5eb87db68cbf967133f4147f12c13462' 'squashfs'
    INSTALL_ZST_ZRCHIVE '9a383353d4bffd9736954c1d2cea6a5a31e4f549a25101cf196e9c512ea0d79d07674f32f214c62500ee94d8ea338812363d2213820884808508183cda70dd35' 'skim'
    INSTALL_ZST_ZRCHIVE '9acedc649b558568478d225fd122c73170fe863e62d417f63083f1dd89f98477e301d552783e7e2d284c7b342116acbf73a92f40a67a89bf2f013148e0b62197' 'uv'
    INSTALL_ZST_ZRCHIVE '9b81eb5d86e4f21a3af8573c7b7d7ea6b91a56b4b152de3a84cdbd1dd9ea3b5b8f3a25d9969890af4acae56c80a3f3f065acc2b614e7ec5a9f6364e78a673834' 'fuc'
    INSTALL_ZST_ZRCHIVE 'a283279e81307fa7f0dfbec490fa8c637b8ec2804e5bfb2f2516ffe3ecef8562f375791629a039d941cd8c771793931871924c296f589f41cc02a21d4de85740' 'ff'
    INSTALL_ZST_ZRCHIVE 'acc3b165d8892aad36942177610020c46d65f89949959828912fb4492970d908b7ee3e5604fd5243459e25df059fb16cd4de8e41acea4e7a03cea8ede33237dc' 'ion'
    INSTALL_ZST_ZRCHIVE 'b2c6b1a865e295ab36902208641fb8075bbba7535ebb29740381644e064d642eaf9ce5695db6218b8047a97213847f64d69e3ded700d57f99a513cb4306b79de' 'bottom'
    INSTALL_ZST_ZRCHIVE 'b2e6fd862902891a0a95f7f59a0fbf6a512354cef2a4c7441d324650d23590272788831077d094b1bb0c78c70714bc7d377c100fc4554b1cb2f02f8bffff1f11' 'navi'
    INSTALL_ZST_ZRCHIVE 'bcc47b69aa74153a4f9d8cf5f4ddc9f223772cdc18419933193d67e0bc8533abc0a4c6fb74ce5433325fda29d6ea4435c3a134f69f2e28f3ee60518b525c89c1' 'ripgrep'
    INSTALL_ZST_ZRCHIVE 'c11a3e29844d311887ecf526508c07fa4dfc0b23fc86f86e7b680c41412a460916b0b763787cef8bf45f78c211218dbfdd121e43506ffcd051400ba06dcec2b2' 'reflicate'
    INSTALL_ZST_ZRCHIVE 'c7f4f29c3e14f5754abd7cfde0a9e1dcaf27978534490d1c329ef56052c4ecc4966b54c773cf32a1291bac894a4067780bb3cf029cc6a05bf9d98bc1d8e0710a' 'runiq'
    INSTALL_ZST_ZRCHIVE '4899322635683a9a2aae1572cfeda4186940b750a32b98b31454a55b60dcc2dee18d7c03ec3c2d317e0bba848416e0ea977042c5fd9323e309e6886a3b41ba51' 'garage'
    INSTALL_ZST_ZRCHIVE 'cc2f60f73ebc6b084bdce9991a94c9be674b5fb8dd33dd0723f82574c0dbf9ba089342fc03f0d0eb88be7e6a7248d657c9c94e60ca3e162cf8a670644157dbfb' 'evil-helix'
    INSTALL_ZST_ZRCHIVE 'cfffaed9795393d6b5333aadec7b615a56b1391aede5bbe68ba301639f135c461b8839d5584ee7223012b8b0c381fa264a23157ea9f561e451172589c31ac5c9' 'byobu'
    INSTALL_ZST_ZRCHIVE 'd657f48a845b009862e728c27910182be49767a1fddccc646aff4aa8c44bd566c4c4764b9b508f448fdb3857cb87fce87be0b137e246fe8a66df5df8b993383f' 'difftastic'
    INSTALL_ZST_ZRCHIVE 'd7f9702d1886f39a0803fd0ce94e6e2b6ea1bc51dc09f6c2b6b093c4a3e0d380521b9bfe3432019794ab0c924d1e4f86c706db3499e457f5db128fc95aac629f' 'television'
    INSTALL_ZST_ZRCHIVE 'd855544cee6a1bbd3adc435123a303cfccce256e750751c4ab49dcad1bb74dcc4fa4707279435d4f2453748380c2ab4155cc66f351a2dec74da8c04d75e2931f' 'ruplacer'
    INSTALL_ZST_ZRCHIVE 'd8b7e24d37f095c317421da838816f32241133ba4107fa60325e4ff3a3e1ec1b076345c59f20eddd58a8c332cbb6827a59768c83a2e48d7574600a528d0e6239' 'zellij'
    INSTALL_ZST_ZRCHIVE 'db06e1d686c9730b0a7886320c1f9bb0570f0d434d7400da50ed60738a4415d2bc954b3541958553efa25fef4e59fd7b2a2d91983a3c854dc4883aa5c70ed155' 'home_config'
    INSTALL_ZST_ZRCHIVE 'dc80f2cd671b80afe4dd13fb74e6ac6a3759ccbd796089749f5a15fc4b21e0f3aedd7d6f8037de922ad6991eedf7a9cf8d4aa63d882f199da96ec026ba0d6418' 'ddh'
    INSTALL_ZST_ZRCHIVE 'e28c49cea5cff530c8305bdd4b3b75e1577d62d412834526c261df9ab671e6aad69319d01288cbb57d339e8f83eb42fdc76a4e4f37d1cf4305311dd916cfa3dc' 'miniserve'
    INSTALL_ZST_ZRCHIVE 'e7304e13a5d6eb2ebc0f4815f3f8daacbf36dbf17e99a32af338b97d399a6da95f7190b8aa1a7b669c665bbffeca1f21f541d9d3e3b784db8fb18ef125c560f3' 'ruff'
    INSTALL_ZST_ZRCHIVE 'ec367c10aaad295316e29e60cd88a315e503acc02f7f6363be84a7abc46dcdd4c4552957cb33c2c8ee3c35ed256bc17ab266988a42c03771fd0a81559b5e5851' 'systemd-manager-tui'
    INSTALL_ZST_ZRCHIVE 'ec9513627e2b63a8ae1613d25b9cb9c9eb18c25d5cdbf848483d34d1bb804ad5a6f9ef304672086a7087eaace4cd0e4c455f0cd835da64867d3346575b94b754' 'dust'
    INSTALL_ZST_ZRCHIVE 'f1a2204bee66b3234b13b41d9c58bac47cbf413789596b8e9a148e07f3fb76c4fa67a82a4f39c8bbf44daf4eb6ca9866d0fbd0d15b6a0c7ebe817d8977d54f8c' 'gitui'
    INSTALL_ZST_ZRCHIVE 'f42fd02742dc8729b02780dd20d801f04ae0ffa58eb78f8d751e743770376d37a7899674441d3a7303488ab9d3636ff420f267ddc6f7ce849896a87e2b54134f' 'fish-shell'
    INSTALL_ZST_ZRCHIVE 'f4b1679c4628d709abbc02ff3ca5e67f01d8611d455770dd8b1067fc20dd347374c717ef0ee5fd579472aa00d67625eca79ade6304c7bb61f202281d661261b2' 'starship'
    INSTALL_ZST_ZRCHIVE 'fce377eaa67ba6e7d6cbbab0a7da9875bf01196c50f4ebfcf8b902c4e90a71c4220bd3342eaef82fed7f3e5df51e0026955659e7ec5e8eb347519a0fe8b8d1c2' 'alacritty'
    INSTALL_ZST_ZRCHIVE 'ff9fae841fa487900d0048b58d4ce8e5ccaaecf1e661dccd17b409eb9c31f62d2736a408e95669e600787d94fe374d412204c1df81153e774571774b74850dc2' 'xsv'
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

get_apt_packages() {
    apt-get -y install \
        'aria2' \
        'automake' \
        'bear' \
        'bison' \
        'build-essential' \
        'clang' \
        'clang-format' \
        'clang-tidy' \
        'clang-tools' \
        'clangd' \
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
        'imagemagick' \
        'ipython3' \
        'jq' \
        'libasound2-dev' \
        'libevent-dev' \
        'libfontconfig-dev' \
        'libgit2-dev' \
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
