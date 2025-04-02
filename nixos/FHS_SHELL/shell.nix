{pkgs ? import <nixpkgs> {}}:
(pkgs.buildFHSEnv {
  name = "simple-x11-env";

  targetPkgs = pkgs:
    (with pkgs; [
      alsa-lib
      bc
      bison
      flex
      gnumake
      libelf
      python312Full
      udev
      zsh
    ])
    ++ (with pkgs.xorg; [
      libX11
      libXcursor
      libXrandr
    ]);

  multiPkgs = pkgs: (with pkgs; [
    alsa-lib
    bc
    bison
    flex
    gnumake
    libelf
    python312Full
    udev
    zsh
  ]);

  runScript = "zsh";
})
.env
