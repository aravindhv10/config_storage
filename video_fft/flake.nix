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
      bc
      bison
      blend2d
      cargo
      cargo-info
      ffmpeg
      ffmpeg.dev
      fish
      flex
      gcc
      gcc14Stdenv
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
      udev
      wezterm
      zellij
      zsh
      zstd
    ];

    mylist = basepkglist;

    fhs = pkgs.buildFHSEnv {
      name = "simple-x11-env";
      targetPkgs = pkgs: mylist;
      multiPkgs = pkgs: mylist;
      runScript = "alacritty -e zellij";
    };
  in {
    devShells.${system}.default = fhs.env;
  };
}
