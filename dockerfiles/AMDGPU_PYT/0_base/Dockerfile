FROM rocm/pytorch:rocm7.1_ubuntu24.04_py3.13_pytorch_release_2.9.1

RUN ln -vfs -- ../opt/venv /root/venv

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get update' \
    && . '/root/important_functions.sh' \
    && get_amd_rocm_packages_ubuntu \
    && echo 'DONE apt-get update' ;
