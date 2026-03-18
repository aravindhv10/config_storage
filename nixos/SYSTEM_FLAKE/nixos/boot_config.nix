{pkgs, ...}: {
  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };

      grub = {
        device = "/dev/nvme0n1";
        efiInstallAsRemovable = false;
        efiSupport = true;
      };

      systemd-boot.enable = false;
    };

    tmp = {
      tmpfsSize = "60%";
      useTmpfs = true;
    };

    initrd = {
      kernelModules = [];

      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "uas"
        "sd_mod"
      ];
    };

    extraModulePackages = [];
    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;

    kernelModules = [
      "kvm-amd"
      "amdgpu"
    ];

    kernelParams = [
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      "zswap.zpool=zsmalloc"
      "zswap.max_pool_percent=60" # Allows zswap to use up to 2 GB of your 8 GB RAM
    ];
  };
}
