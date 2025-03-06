# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
#  boot.kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_stable;
  boot.kernelParams = [ "zswap.enabled=1" "zswap.max_pool_percent=80" ];

  fileSystems."/tmp" =
    { device = "none";
      fsType = "tmpfs";
    };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  # services.displayManager.sddm.enable = true;
  services.xserver.displayManager.gdm.enable = true;

  services.desktopManager.plasma6.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  documentation.enable = true;
  documentation.man.enable = true;
  documentation.dev.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.asd = {
    isNormalUser = true;
    description = "asd";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    acpi
    alacritty
    aria2
    atuin
    bat
    ruff
    bottom
    brave
    byobu
    dnsmasq
    dust
    emacs30
    fd
    fish
    fishPlugins.done
    fishPlugins.forgit
    fishPlugins.fzf-fish
    fishPlugins.grc
    fishPlugins.hydro
    flatpak
    foot
    fzf
    gcc
    gdm
    git
    grc
    helix
    htop
    lsd
    man-pages
    man-pages-posix
    mpv
    neovim
    nushell
    parted
    python3Full
    qbittorrent-enhanced
    rclone
    ripgrep
    skim
    squashfsTools
    starship
    tmux
    unzip
    uv
    vim
    wezterm
    wget
    yazi
    zip
    zoxide
    ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  
services.dnsmasq = {
    enable = true;

    alwaysKeepRunning = true;
    resolveLocalQueries = true;

    settings = {
      server = [ "192.168.1.254" "4.2.2.2" "8.8.8.8" "8.8.8.4" "8.8.4.4" "76.76.2.0" "76.76.10.0" "9.9.9.9" "149.112.112.112" "208.67.222.222" "208.67.220.220" "1.1.1.1" "1.0.0.1" "94.140.14.14" "94.140.15.15" "185.228.168.9" "185.228.169.9" "76.76.19.19" "76.223.122.150" ] ;
      local-service = true; # Accept DNS queries only from hosts whose address is on a local subnet
      log-queries = true; # Log results of all DNS queries
      bogus-priv = true; # Don't forward requests for the local address ranges (192.168.x.x etc) to upstream nameservers
      domain-needed = true; # Don't forward requests without dots or domain parts to upstream nameservers

      dnssec = true; # Enable DNSSEC
      # DNSSEC trust anchor. Source: https://data.iana.org/root-anchors/root-anchors.xml
      trust-anchor = ".,20326,8,2,E06D44B80B8F1D39A95C0B0D7C65D08458E880409BBC683457104237C7F8EC8D";
    };
  };

 
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
