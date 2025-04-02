{pkgs ? import <nixpkgs> {}}: let
  mylist = [
    pkgs.alsa-lib
    pkgs.bc
    pkgs.bison
    pkgs.flex
    pkgs.gnumake
    pkgs.libelf
    pkgs.python312Full
    pkgs.udev
    pkgs.zsh
    pkgs.xorg.libX11
    pkgs.xorg.libXcursor
    pkgs.xorg.libXrandr
  ];
in
  (pkgs.buildFHSEnv {
    name = "simple-x11-env";

    targetPkgs = pkgs: mylist;

    multiPkgs = pkgs: mylist;

    runScript = "zsh";
  })
  .env
