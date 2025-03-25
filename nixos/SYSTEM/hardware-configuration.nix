{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/linux";
    fsType = "btrfs";
    options = ["subvol=@" "compress=zstd:3"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/efi";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [{device = "/dev/disk/by-partlabel/swap0";}];
}
