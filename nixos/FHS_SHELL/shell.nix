{pkgs ? import <nixpkgs> {}}: let
  mylist = with pkgs; [
    bc
    bison
    blend2d
    ffmpeg
    ffmpeg.dev
    fish
    flex
    gnumake
    libelf
    openssl
    openssl.dev
    python313Full
    udev
    zsh
    zstd

    (pkgs.python312.withPackages (ps:
      with ps; [
        albumentations
        einops
        fastapi
        flask
        inotify-simple
        ipython
        jax
        lightning
        matplotlib
        multiprocess
        numpy
        onnxruntime
        opencv-python
        pillow
        python-multipart
        requests
        safetensors
        tensorboard
        tensorboardx
        timm
        torch
        torchmetrics
        torchvision
        transformers
        uvicorn
        yt-dlp
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
