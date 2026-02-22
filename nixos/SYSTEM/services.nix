{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  services.desktopManager.plasma6.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services = {
    # Enable the X11 windowing system.
    # You can disable this if you're only using the Wayland session.
    # xserver = {
    #     enable = true;
    #     videoDrivers = ["amdgpu"];
    # };

    displayManager = {
      gdm.enable = false;
      # gnome.enable = true ;
      # plasma6.enable = true;
    };

    # displayManager.sddm = {
    #       enable = true;
    #       wayland.enable = true;
    #       settings.General.DisplayServer = "wayland";
    # }

    # displayManager.sessionPackages = [ unstable.wayfire ];

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
