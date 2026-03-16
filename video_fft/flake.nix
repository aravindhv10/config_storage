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

    basepkglist = with pkgs; [
      atuin
      bc
      bison
      blend2d
      cargo
      cargo-info
      cargo-watch
      cmake
      eza
      fd
      ffmpeg
      ffmpeg.dev
      fish
      flex
      fzf
      gcc
      gcc14Stdenv
      git
      gnumake
      helix
      libelf
      libgcc
      llvmPackages_20.clang
      llvmPackages_20.clang-tools
      openssl
      openssl.dev
      pkg-config
      rust-analyzer
      rust-bindgen
      rustc
      rustfmt
      starship
      udev
      wezterm
      zellij
      zsh
      zstd
    ];

    pythonpkglist = with pkgs; [
      # python313

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

    mylist = basepkglist ++ pythonpkglist;

    fhs = pkgs.buildFHSEnv {
      name = "simple-x11-env";
      targetPkgs = pkgs: mylist;
      multiPkgs = pkgs: mylist;
      runScript = "export LIBTORCH_USE_PYTORCH=1 ; zsh";
    };
  in {
    devShells.${system}.default = fhs.env;
  };
}
