{
  config,
  lib,
  pkgs,
  modulesPath,
  unstable,
  ...
}: {
  imports = [
    ./boot_config.nix
    ./environment.nix
    ./hardware-configuration.nix
    ./i18n.nix
    ./network_config.nix
    ./programs.nix
    ./services.nix
  ];

  security.rtkit.enable = true;
  time.timeZone = "Asia/Kolkata";

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = true;
  };

  users = {
    defaultUserShell = pkgs.zsh;

    users.asd = {
      isNormalUser = true;
      shell = unstable.fish;
      description = "asd";
      extraGroups = ["networkmanager" "wheel" "audio" "incus-admin" "libvirtd"];
      packages = with pkgs; [
        kdePackages.kate
      ];
    };

    groups.libvirtd.members = ["asd"];
  };

  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
    containers.enable = true;
    incus.enable = true;

    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  system.stateVersion = "24.11";
}
