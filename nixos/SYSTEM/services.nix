{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver = {
    enable = true;
    videoDrivers = ["amdgpu"];
  };
}
