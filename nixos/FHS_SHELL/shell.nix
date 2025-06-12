{pkgs ? import <nixpkgs> {}}: let
  mylist = with pkgs; [
    bc
    bison
    flex
    gnumake
    libelf
    openssl
    openssl.dev
    python312Full
    udev
    zsh
    zstd

    (pkgs.python312.withPackages (ps:
      with ps; [
        albumentations
        einops
        inotify-simple
        ipython
        multiprocess
        numpy
        opencv-python
        pillow
        requests
        safetensors
        torch
        torchvision
        transformers
      ]))
  ];
in
  (pkgs.buildFHSEnv {
    name = "simple-x11-env";

    targetPkgs = pkgs: mylist;

    multiPkgs = pkgs: mylist;

    runScript = "fish";
  })

.env
