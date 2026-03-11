{
  pkgs,
  unstable,
  ...
}:
{
  users = {
    defaultUserShell = pkgs.zsh;
    groups.libvirtd.members = ["asd"];

    users.asd = {
      description = "asd";
      isNormalUser = true;
      shell = unstable.fish;
      packages = [pkgs.kdePackages.kate];

      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "incus-admin"
        "libvirtd"
      ];
    };
  };
}
{
  config,
  lib,
  pkgs,
  unstable,
  ...
}: {
  imports = [
    ./boot_config.nix
    ./configuration.nix
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

  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
    containers.enable = true;
    incus.enable = true;

    podman = {
      enable = true;
      dockerCompat = true;
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
