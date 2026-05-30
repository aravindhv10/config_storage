{
  pkgs,
  unstable,
  ...
}: {
  programs = {
    firefox.enable = true;
    virt-manager.enable = true;

    niri = {
      enable = false;
      package = unstable.niri;
    };

    hyprland = {
      enable = false;
      package = unstable.hyprland;
      withUWSM = true;
      # withUWSM = false;
      xwayland.enable = true;
    };

    wayfire = {
      enable = false;
      package = unstable.wayfire;
      # package = pkgs.wayfire;
      plugins = [
        unstable.wayfirePlugins.wayfire-plugins-extra
        unstable.wayfirePlugins.wcm
        unstable.wayfirePlugins.wf-shell
      ];
    };

    fish = {
      enable = true;
      package = unstable.fish;
    };

    zsh = {
      enable = true;
    };
  };
}
