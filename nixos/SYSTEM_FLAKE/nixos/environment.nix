{
  config,
  lib,
  pkgs,
  modulesPath,
  unstable,
  ...
}: {
  environment = {
    etc."greetd/environments".text = ''
      wayfire
      fish
      bash
    '';

    variables = {
      ROC_ENABLE_PRE_VEGA = "1";
      EDITOR = "hx";
      QT_SCALE_FACTOR = "1.25";
    };

    gnome.excludePackages = with pkgs; [
      atomix # puzzle game
      cheese # webcam tool
      epiphany # web browser
      geary # email reader
      gedit # text editor
      gnome-characters
      gnome-music
      gnome-photos
      gnome-terminal
      gnome-tour
      hitori # sudoku game
      iagno # go game
      tali # poker game
      totem # video player
      seahorse
    ];
  };
}
