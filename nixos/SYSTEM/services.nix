{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {

  services = {

    # Enable the X11 windowing system.
    # You can disable this if you're only using the Wayland session.
    # xserver = {
    #     enable = true;
    #     videoDrivers = ["amdgpu"];
    # };

    # displayManager.sddm = {
    #       enable = true;
    #       wayland.enable = true;
    #       settings.General.DisplayServer = "wayland";
    # }

    displayManager.gdm.enable = false ;
    desktopManager.gnome.enable = true ;
    greetd = {
        enable = true;
        settings = rec {
        initial_session = {
            command = "${pkgs.uwsm}/bin/uwsm start ${pkgs.wayfire}/bin/wayfire";

            user = "asd";
        };
        default_session = initial_session;
        };
    }
  } ;
}
