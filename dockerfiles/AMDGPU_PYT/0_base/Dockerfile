FROM rocm/pytorch:rocm7.1_ubuntu24.04_py3.13_pytorch_release_2.9.1 as pytorch

FROM rocm/dev-ubuntu-24.04:7.1.1-complete

COPY --from=pytorch /opt/venv /opt/venv

RUN ln -vfs -- ../opt/venv /root/venv
