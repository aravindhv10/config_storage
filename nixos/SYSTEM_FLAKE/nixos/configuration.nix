{
  config,
  lib,
  pkgs,
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
    ./users.nix
    ./virtualization.nix
  ];

  security.rtkit.enable = true;
  time.timeZone = "Asia/Kolkata";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = true;
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
