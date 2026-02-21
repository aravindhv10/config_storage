{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
      grub.device = "/dev/nvme0n1";
      grub.efiInstallAsRemovable = false;
      grub.efiSupport = true;
      systemd-boot.enable = false;
    };

    tmp = {
      tmpfsSize = "60%";
      useTmpfs = true;
    };

    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "ahci" "uas" "sd_mod"];
      kernelModules = [];
    };

    extraModulePackages = [];
    kernelModules = ["kvm-amd" "amdgpu"];
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
    kernelParams = ["zswap.enabled=1" "zswap.max_pool_percent=80"];
  };
}
