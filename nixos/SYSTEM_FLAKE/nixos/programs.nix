{
  config,
  lib,
  pkgs,
  modulesPath,
  unstable,
  ...
}: {
  programs = {
    firefox.enable = true;
    virt-manager.enable = true;

    niri = {
      enable = true;
      package = unstable.niri;
    };

    hyprland = {
      enable = true;
      package = unstable.hyprland;
      withUWSM = true; # recommended for most users
      # withUWSM = false; # recommended for most users
      xwayland.enable = true; # Xwayland can be disabled.
    };

    wayfire = {
      enable = true;
      # package = unstable.wayfire;
      plugins = [
        pkgs.wayfirePlugins.wayfire-plugins-extra
        pkgs.wayfirePlugins.wcm
        pkgs.wayfirePlugins.wf-shell
      ];
    };

    fish = {
      enable = true;
      package = unstable.fish;
    };

    zsh = {
      enable = true;
      ohMyZsh = {
        enable = true;
        plugins = [
          "eza"
          "fzf"
          "git"
          "procs"
          "starship"
          "systemd"
          "zoxide"
        ];
        theme = "robbyrussell";
      };
    };
  };
}
