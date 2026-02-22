{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.

  services = {
    xserver = {
      enable = true;
      videoDrivers = ["amdgpu"];
      displayManager.gdm.enable = false;
    };

    # displayManager.sddm = {
    #       enable = true;
    #       wayland.enable = true;
    #       settings.General.DisplayServer = "wayland";
    # }

    desktopManager.gnome.enable = true;
  };
}
