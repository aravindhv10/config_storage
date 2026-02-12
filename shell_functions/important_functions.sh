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
    make -j
    make -j install
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

    get_rust_package 'https://github.com/chmln/sd.git'
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

    get_tmux
    get_byobu
    get_squashfs_tools
}

INSTALL_ZST_ZRCHIVE () {
    cd '/var/tmp'
    rm -rf "${2}"
    adown \
            "https://github.com/aravindhv10/config_storage/releases/download/v1.0/${2}.tar.zst" \
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
    INSTALL_ZST_ZRCHIVE 'e1428ed67f37c27eb907d74e21df851ff950d9ba444f7102ddcbdf55cd26d15d71f8a6a0a1379c4dc14501e35861d2b6b1907ea2b96c5b1dcf2075cf18e8b971' 'zoxide'
    INSTALL_ZST_ZRCHIVE '9a7dc7d211014bbb8cb6ee508badd05e489ded0cca5128bbfb7621022bd346f7a9ee202788134df93cc9ace820bd2270726c9274fd71580b7dac254260c5c0a4' 'watchexec'
    INSTALL_ZST_ZRCHIVE '8f49b6b30490adcc7d9830fdea7c5b8a86e6f7cd77d11afa95237871f1ccd3c6669f152c2af32ff283f8c1158784764b3c189319e1ef26fbc7ade83a3597b0e2' 'television'
    INSTALL_ZST_ZRCHIVE '940b4e290b9f2cf54086647718711f4bf1cc0d9ea6042d962a9e4fdc11fa4b12ef83bfd5a4377af9bf4ae955aed11fcbff2909e86d24473e830dd94a12093234' 'tmux'
    INSTALL_ZST_ZRCHIVE '4f32af70656c2ca95cee962c6e96a135d4908516ad60a1226ad05a401da0ee9384f2afc83538d911884fb5f76264f8d3a65a2dd6e14c3092e4b4f2e88e5a43d0' 'yazi'
    INSTALL_ZST_ZRCHIVE '188179f64a4d8efab009f7b932438a1e56cce4e1cdd0f30c6f2220f6a96bf588bfba4d00d95a85cc6e42099d17cd01b1b6d52ebef84b8f12eadcd428ccd05567' 'texlab'
    INSTALL_ZST_ZRCHIVE '56722a63a5449a2c77fc3767e4a91004988782d12d0594010aa3fe85a832bdbac6d73260a972b6d4b06f8fc8adec680a4bbf32e4e5c690bda47b38a02e958d48' 'systemd-manager-tui'
    INSTALL_ZST_ZRCHIVE '2ac2230063cef6931aa80ba0076b0f089031059d38e604b965a92492859780fb33ce4fc204c24c1add84eb4835beaed0d009a4f5f3200b36f8736636c2ec9e86' 'squashfs'
    INSTALL_ZST_ZRCHIVE '2f3f9d3cd31e8101df7dbbf2be2112f74de1b5638a2b8f87a30c17e9c2b5ebab071d98272f910c9f04623138b7dd48b24f0740346b51c510edb38fff43eb1a36' 'zellij'
    INSTALL_ZST_ZRCHIVE 'cf79fa71cd84a7ab9b11371f718a89550d0e37ab0953a619771d8a9b274930ee817c2a886edcbfa95a5111a115712f41b3331f75f5227811ca36578250c6d3f6' 'skim'
    INSTALL_ZST_ZRCHIVE '19dcb665094f850f4d0c6d6a5d35d22cfda7d3fbf9204233dcb3e8a40f180fb752195aeacfef03b90a1bdb41731fcf7ad317d6b7ce4da8c05aeb8dbf872f7138' 'sd'
    INSTALL_ZST_ZRCHIVE '023789a8eaef77fbc7638d77aa10844a3a55ccb056515cb4499792b49a9a4b8ece8725f9907bde9696cdf0814fe4becabb18bf4cfd3e03e52a7b9c4469190876' 'starship'
    INSTALL_ZST_ZRCHIVE 'ceb6b925a1f11949109f579629bb323575a0cd715170d6169e815e07924b19c7331b8a9310624744b3c7585edb27054ef81cbb445b3362fe59bade1c17c4a233' 'ruplacer'
    INSTALL_ZST_ZRCHIVE '054a894f351e2766eb3e07d7b495aab00d160d286ffab15382c8f7613d807d6cdab060f161b059197710a2dc1c44cebc22e2c37fd8e15d8600363b72b627aaba' 'xsv'
    INSTALL_ZST_ZRCHIVE 'a4321b2717bea76066719df46204f9ab7ca7bb33f837756c0afef56d007e0748271316c0d06164e51a8819103bbad7658a003490e73535f436deb99e30f77ac4' 'rust-bindgen'
    INSTALL_ZST_ZRCHIVE 'f3960ecaeceb779783f70323809a27c8bbd9e9c6b7ed4756f5d729723ca7a51dc46e6582f9874c16f745af0a61b4bba15804dfb5b9ca59ce9a9052aa7ed12327' 'dust'
    INSTALL_ZST_ZRCHIVE '2f57bbaf450fed7ec8c816e8c3932cbaee740217681f4b633f7f90a815aac79278ebafa6349d97a0a0f0d1121bf85c61d767769e98f89b54583f43a693eb8280' 'miniserve'
    INSTALL_ZST_ZRCHIVE '1324e895d91618af7fc625014c411a3d23ef12584084e8c20f179c9da97e20f15ad71aff68aed721586acd8fb296fc525d0374c020f472d8744c84e7e8e168de' 'reflicate'
    INSTALL_ZST_ZRCHIVE '5a4ded2b40829fff7328f78164febcf927c7c5a892e815c0a9d481020c5901838ed38510004cc70ab1eb62802af7bfca5c3494e0d88e552de74ce5a154cca57a' 'runiq'
    INSTALL_ZST_ZRCHIVE 'd3f905660f5778730b973d002c580205fde3486569b4dd352511c5b35193fcbe82e721be49068d6f82adafc99aa7a7f99aae8c718bc8b79c9fe4d318928b7a7e' 'Tuckr'
    INSTALL_ZST_ZRCHIVE 'cff6fb2bec3b5a258f8b7a328c42c73ae8461e668b452d905ebfe7805c939e7afc528e857754ecf57695f2f21550da1cf70986b677226748973857da4bfbb336' 'uv'
    INSTALL_ZST_ZRCHIVE 'dcdadfe2b1e1b95e79e0a9171c1ef5deb4985e60827661ec9816960a665c6920ae0a955604a12c53d59090e7082c4c3a70093f5b39705a2de0e6ed29edf006d7' 'lsd'
    INSTALL_ZST_ZRCHIVE '7b74ed6ae4048aa57ff7188558d4edff1554bb4c74eb89e84a04abdf35ca8aeae662764db7930831ad4729f59a57c2dcbd7418450cfa8c82a7cb75b926549714' 'deb_mirror'
    INSTALL_ZST_ZRCHIVE '41d949964d2b9394ac5dcc7a654e884cec6aa8dc60a33ea4b720bc674576a825b6e0736dc4f9b3578efbf0032d5f9d66faa481ecabab22341d5c440233d81373' 'difftastic'
    INSTALL_ZST_ZRCHIVE '80de3ebdaab67accec56561e40c9842dd04c99a44227c36076634a18dc64600274d21d25c2a1b04b042a2da1bb8673d51fe3f910af77e5a838a57f4404d9c4da' 'ion'
    INSTALL_ZST_ZRCHIVE '587f9c392f170a68efad79b1a95791a621cf8fabe70b87f74cd57e1f9e6094ab96d379e974f631aa49e70dae302394572ab2c87586a28602a7ec5743d331e517' 'bottom'
    INSTALL_ZST_ZRCHIVE 'afd9fef7b65767fea11afae1d8574b7f1d216dc65456e0a08885d26d33899d88e9460b3db2a0175427785838967217c3ae05faa128869b66a9d627c801469ccf' 'procs'
    INSTALL_ZST_ZRCHIVE '950e0f1196a684032ed065771bdd791fa230dfb69f743c08d5b1eb2f6ed276dac2b68215233b747eba45ffb83a4565700fd0698f3fd043646abe96c37102d4a9' 'byobu'
    INSTALL_ZST_ZRCHIVE '855f40e3f36879a624e8ece6be110988846b3045cc4bf99f9ddad1f39896f7e08892421dbd089da2f069c90f2bc39fea6ee2fd5ea936a770010666b9718a21bb' 'tabiew'
    INSTALL_ZST_ZRCHIVE 'd951028ead6565ab599caca7623fcab6773f2339567623ee930dad4ef359180af9e52cecd98fa36aa83b5e5bce81e77e9194f15f4f65a509f7551c71de212dbd' 'ddh'
    INSTALL_ZST_ZRCHIVE '5085ba322b43dddc09ec38240deaba80a9a61ca3e72ca4efce6ce8fa8ac18e85a2f4c87c52e44e6b2cca9f7a7c04a7f9082fb42c575a41b5617c2ef585ae68f3' 'imge'
    INSTALL_ZST_ZRCHIVE 'd07cfb05ca24356f7f4147e25948405aa990dec646b4b0cdf4f9402a81ebe4ab090e66fb1bb6a191d935378b45e8593ebc1e44683bedd74a29f37ea91b8ec4d6' 'fuc'
    INSTALL_ZST_ZRCHIVE '9d284c007403eab43a06d7293210806671db219532574110222d5f5a5e9cc65f7867917f09f0ee09ff3c83b3b652baf3f04ace0e9bac6fe02c60edbb658edda9' 'ripgrep'
    INSTALL_ZST_ZRCHIVE '86a00ef23091b7a343f49b928cecc0ad21c2f5075401fc7c71a3be4715b179c4583e2628ef61e0408896f61f36cf992acb69a1f9db5fe4721da1b7f687aeaacf' 'alacritty'
    INSTALL_ZST_ZRCHIVE '3b12e01a1b41db250aa267d30e16d16a38b3066847e1c878d84bcf5596aa2c2aa22feac6fa8c05f77653ee089545af208ae7421fb7da5617e3d239ebc079d61f' 'navi'
    INSTALL_ZST_ZRCHIVE '62ce74f3bf9302bfdb0833dc14a1f706b8291f58cbeb0b294bfbb2d7722e2308b369c9027490810f5514b90d03a7270f39d5f207ebda117f0830ad555fababdc' 'bat'
    INSTALL_ZST_ZRCHIVE '71e12f4d53d2e8ee415c3b1669b8f7b9ed0a384a62740a6d82ea985a3120b5f49450bb0c1ee6421cb5cb03b4f188976dafa859d43b4d6b058669affdafd15eeb' 'atuin'
    INSTALL_ZST_ZRCHIVE '6ceb859c6221a9dc16b369b9def2bad936dbf438833efd481629d26ea8025143945260dd6d88aab795daf093a813e305dd7647a92e3840488dea6ada0f9513bb' 'evil-helix'
    INSTALL_ZST_ZRCHIVE 'e08245e9075ab1bdbe1cd947db9a58185c8ec39d76c235e877a5f4e001ef1c715376dc908ab68e8caa0912b779572daf6da1a39b21f2ff4394ef44cfe97a71dc' 'ff'
    INSTALL_ZST_ZRCHIVE 'a8c8b5588a0900913d7471e39fec9f5bf4dd63cb953675590025ef276ad3d0805daf6f67d93e3839fac5087edd9e3d3fd18583a4312fa9b77c971208e95346dc' 'hyperfine'
    INSTALL_ZST_ZRCHIVE '5bc65a3f8f866738f4f7754cbdcefa26423b7f0a5d62875a020ae2d9dfd0273fd9fc78f29df0b271ff630ffeb1c20252eeeec96848aa9126ab07074aecf5af98' 'fish-shell'
    INSTALL_ZST_ZRCHIVE 'aee3243108b5ffe9b4f2cc6c67bde3170dc19c2417733aade38ada9b24f335bebc0bc105368c96780b20be83675408e13cf3fdcf31f29430b31de62f8151d5b8' 'igrep'
    INSTALL_ZST_ZRCHIVE '7c86af8d2261e12f8d57411b0ec183dda5c6f7598634a14cb3ea91e3619813af6c4e441d43d31c875620aa2e139e9c1dae4b4943de5875fc64d65e87afd1b526' 'fd'
    INSTALL_ZST_ZRCHIVE '663ccc0a70451a8974e5efbd1426c7a76d1c82fac5696811ef1573d28c27c47f4001025de579f8dc22497349a12842d0f54aae06659a2f2299e069910838a9a6' 'nushell'
    INSTALL_ZST_ZRCHIVE 'db47d3db37794453ccecd1a502306d8dce0757da66767b0c9b266d830baa535364046d080e3b62b81098722a89b4ad44e47dfdb9de873b2aba5f9f3a4243578c' 'eza'
    INSTALL_ZST_ZRCHIVE 'bd9da2af49346e71af7e917c907e7c13322735d6209d3b2d744b3401fbc27e00bb86c23b2017c045ea3551ab99d2353c05efdd32d295ce8b747541a90ab48a63' 'gitui'
    INSTALL_ZST_ZRCHIVE 'ac2a640ff47c9fe924da76776f1824d436529ad9b1ede908745fc83aa626e28f12f547a1cc3abe01f595c333b4517881e9650e70b5d171a3095d31cdfb7369bc' 'ruff'
    INSTALL_ZST_ZRCHIVE '7e2cd3cca80c99b11cefe6d833801ab3af6459fe736d9f93b0aee739e9fcd22656340f56fa89423794be4563e7664d900c99c5c5957758291cb37907197b546d' 'helix'
    INSTALL_ZST_ZRCHIVE '04f11532373a11d0a935c4a4cc3fbb6562f5796cdc2d6bf39c216979a5378e7bdc67ba0539144c0ee599a5c5a5ae346bb80e71f5c7aa2430509da97e605738ad' 'home_config'
}

get_all_good_programs_and_config () {
    INSTALL_ALL_GOOD_PACKAGES
    cd '/var/tmp/'
    home_config
}

get_amd_rocm_packages_ubuntu() {

echo 'START install wget' \
&& apt-get update \
&& apt-get install wget \
&& echo 'DONE install wget' ;

mkdir --parents --mode=0755 /etc/apt/keyrings

echo 'START get gpg certificate' \
&& wget 'https://repo.radeon.com/rocm/rocm.gpg.key' -O - \
| gpg --dearmor \
| tee '/etc/apt/keyrings/rocm.gpg' > /dev/null \
&& echo 'DONE get gpg certificate' ;

tee /etc/apt/sources.list.d/rocm.list << EOF
deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/7.1.1 noble main
deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/graphics/7.1.1/ubuntu noble main
EOF

tee /etc/apt/preferences.d/rocm-pin-600 << EOF
Package: *
Pin: release o=repo.radeon.com
Pin-Priority: 600
EOF

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
        'graphicsmagick-imagemagick-compat' \
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
