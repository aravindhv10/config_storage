{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
  boot.kernelParams = ["zswap.enabled=1" "zswap.max_pool_percent=80"];
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "uas" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd" "amdgpu"];
  boot.extraModulePackages = [];
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "60%";
}
