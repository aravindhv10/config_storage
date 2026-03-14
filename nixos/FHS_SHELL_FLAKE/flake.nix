{
  description = "FHS development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux"; # Adjust this to "aarch64-linux" if on ARM

    pkgs = import nixpkgs {inherit system;};

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
      pkg-config
      python313
      udev
      zsh
      zstd

      (python313.withPackages (ps:
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

    fhs = pkgs.buildFHSEnv {
      name = "simple-x11-env";
      targetPkgs = pkgs: mylist;
      multiPkgs = pkgs: mylist;
      runScript = "fish";
    };
  in {
    devShells.${system}.default = fhs.env;
  };
}
