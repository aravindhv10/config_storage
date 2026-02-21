{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  boot.extraModulePackages = [];
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "uas" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd" "amdgpu"];
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
  boot.kernelParams = ["zswap.enabled=1" "zswap.max_pool_percent=80"];
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.efiInstallAsRemovable = false;
  boot.loader.grub.efiSupport = true;
  boot.loader.systemd-boot.enable = false;
  boot.tmp.tmpfsSize = "60%";
  boot.tmp.useTmpfs = true;
}
