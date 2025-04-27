{pkgs ? import <nixpkgs> {}}: let
  mylist = with pkgs; [
    alsa-lib
    bc
    bison
    flex
    gnumake
    libelf
    openssl
    openssl.dev
    python312Full
    udev
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    zsh
    zstd

    (pkgs.python312.withPackages (ps:
      with ps; [
        numpy
        opencv-python
        ipython
        yt-dlp
      ]))
  ];
in
  (pkgs.buildFHSEnv {
    name = "simple-x11-env";

    targetPkgs = pkgs: mylist;

    multiPkgs = pkgs: mylist;

    runScript = "zsh";
  })

.env
