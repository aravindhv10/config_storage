FROM docker.io/nixos/nix
RUN nix-channel --update

USER root
ENV HOME=/root
WORKDIR /root

COPY shell.nix /root/shell.nix

RUN nix-shell
