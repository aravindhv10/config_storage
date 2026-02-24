{
  config,
  lib,
  pkgs,
  modulesPath,
  unstable,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/linux";
    fsType = "btrfs";
    options = ["subvol=@" "compress=zstd:3" "autodefrag"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/efi";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [{device = "/dev/disk/by-partlabel/swap0";}];
}
