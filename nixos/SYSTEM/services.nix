{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  services.xserver = {
    enable = true;
    videoDrivers = ["amdgpu"];
  };
}
