{
  config,
  lib,
  pkgs,
  modulesPath,
  unstable,
  ...
}: {
  services = {
    desktopManager = {
      plasma6.enable = true;
      gnome.enable = true;
    };

    # Enable the X11 windowing system.
    # You can disable this if you're only using the Wayland session.
    # xserver = {
    #     enable = true;
    #     videoDrivers = ["amdgpu"];
    # };

    displayManager = {
      gdm.enable = false;
      sddm = {
        enable = false;
        wayland.enable = false;
        settings.General.DisplayServer = "wayland";
      };
    };

    displayManager.sessionPackages = [unstable.wayfire];

    greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "${pkgs.uwsm}/bin/uwsm start ${pkgs.wayfire}/bin/wayfire";
          user = "asd";
        };
        default_session = initial_session;
      };
    };
  };
}
