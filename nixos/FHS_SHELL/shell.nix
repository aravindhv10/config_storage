{pkgs ? import <nixpkgs> {}}:
(pkgs.buildFHSEnv {
  name = "simple-x11-env";

  targetPkgs = pkgs:
    (with pkgs; [
      udev
      alsa-lib
      zsh
      gnumake
      flex
      bison
      bc
      libelf
      python312Full
    ])
    ++ (with pkgs.xorg; [
      libX11
      libXcursor
      libXrandr
    ]);

  multiPkgs = pkgs: (with pkgs; [
    udev
    alsa-lib
    zsh
    gnumake
    flex
    bison
    libelf
    bc
  ]);

  runScript = "zsh";
})
.env
