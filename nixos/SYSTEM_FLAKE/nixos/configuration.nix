{
  config,
  lib,
  pkgs,
  modulesPath,
  unstable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./boot_config.nix
    ./network_config.nix
    ./i18n.nix
    ./services.nix
    ./environment.nix
  ];

  security.rtkit.enable = true;
  time.timeZone = "Asia/Kolkata";

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  programs = {
    firefox.enable = true;
    virt-manager.enable = true;

    niri = {
      enable = true;
      package = unstable.niri;
    };

    hyprland = {
      enable = true;
      package = unstable.hyprland;
      withUWSM = true; # recommended for most users
      # withUWSM = false; # recommended for most users
      xwayland.enable = true; # Xwayland can be disabled.
    };

    wayfire = {
      enable = true;
      # package = unstable.wayfire;
      plugins = [
        pkgs.wayfirePlugins.wayfire-plugins-extra
        pkgs.wayfirePlugins.wcm
        pkgs.wayfirePlugins.wf-shell
      ];
    };

    fish = {
      enable = true;
      package = unstable.fish;
    };

    zsh = {
      enable = true;
      ohMyZsh = {
        enable = true;
        plugins = [
          "eza"
          "fzf"
          "git"
          "procs"
          "starship"
          "systemd"
          "zoxide"
        ];
        theme = "robbyrussell";
      };
    };
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

  system.stateVersion = "24.11";
}
