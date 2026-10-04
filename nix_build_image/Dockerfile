FROM docker.io/nixos/nix
RUN nix-channel --update

COPY shell.nix /root/shell.nix
USER root
WORKDIR /root
RUN nix-shell

USER root
WORKDIR /root
RUN nix-shell
