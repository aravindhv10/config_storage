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

    # kernelPackages = pkgs.linuxPackages_6_14;
    # kernelPackages = pkgs.linuxPackages_6_15;
    # kernelPackages = pkgs.linuxPackages_6_16;
    # kernelPackages = pkgs.linuxPackages_6_17;

    # kernelPackages =
    # let
    #     linux_sgx_pkg = { fetchurl, buildLinux, ... } @ args:
    #         buildLinux (
    #             args // rec {
    #                 version = "6.13.11-xanmod1" ;
    #                 modDirVersion = version;
    #                 src = /home/asd/GITLAB/xanmod/linux-6.13.11.tar; # /home/asd/GITLAB/xanmod/linux-6.12.19.tar;
    #                 kernelPatches = [];
    #                 extraConfig = ''
    #                 '';
    #                 extraMeta.branch = version ;
    #             } // (args.argsOverride or {})
    #         );
    #     linux_sgx = pkgs.callPackage linux_sgx_pkg{};
    # in
    #     pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_sgx);
  };
}
