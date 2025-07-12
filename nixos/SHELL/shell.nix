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
        lightning
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
        torchvision
        transformers
        uvicorn
        yt-dlp
      ]))
  ];
in (pkgs.mkShell {
  name = "good_python_env";

  packages = mylist;

  runScript = "fish";
})
