{ config, lib, pkgs, modulesPath, ... }:

let

unstable = import <nixos-unstable> {} ;

in

{

imports = [./hardware-configuration.nix];

boot.loader = {

efi = {
  canTouchEfiVariables = true;
  efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
};

grub = {

efiSupport = true;

device = "/dev/nvme0n1";

extraEntries = ''

menuentry "debian" {
    linux /k root=/dev/disk/by-partlabel/linux rootflags=subvolid=904 dolvm zswap.enabled=1 zswap.max_pool_percent=80 zswap.zpool=zsmalloc
    initrd /i
}

menuentry "nixos_debian_kernel" {
    linux /k root=/dev/disk/by-partlabel/linux rootflags=subvol=@ init=/nix/store/rd4d341n7gs3pvagdrc5bghldz9ny4p8-nixos-system-nixos-24.11.715519.ebe2788eafd5/init dolvm zswap.enabled=1 zswap.max_pool_percent=80 zswap.zpool=zsmalloc
    initrd /i
}

'' ;

};

};

networking.useDHCP = lib.mkDefault true;

nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "uas" "sd_mod" ];
boot.initrd.kernelModules = [];
boot.kernelModules = [ "kvm-amd" "amdgpu" ];
boot.extraModulePackages = [];

environment.variables = {ROC_ENABLE_PRE_VEGA = "1";};

hardware.opengl.extraPackages = [pkgs.amdvlk pkgs.rocmPackages.clr.icd];

systemd.tmpfiles.rules = [
  "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
];

hardware.graphics.enable32Bit = true;
hardware.opengl.extraPackages32 = [pkgs.driversi686Linux.amdvlk];

boot.kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_stable;

boot.kernelParams = [ "zswap.enabled=1" "zswap.max_pool_percent=80" ];

fileSystems."/tmp" = {device = "none"; fsType = "tmpfs";};

networking.hostName = "nixos";

networking.networkmanager.enable = true;

time.timeZone = "Asia/Kolkata";

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

services.xserver.enable = true;
services.xserver.videoDrivers = [ "amdgpu" ];

services.displayManager.sddm.enable = true;
services.displayManager.sddm.wayland.enable = true;
services.displayManager.sddm.settings.General.DisplayServer = "wayland";

services.xserver.displayManager.gdm.enable = true;

services.desktopManager.plasma6.enable = true;

services.xserver.xkb = {
  layout = "us";
  variant = "";
};

services.printing.enable = true;
documentation.enable = true;
documentation.man.enable = true;
documentation.dev.enable = true;

# hardware.pulseaudio.enable = false;
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

# services.pipewire.extraConfig.pipewire."91-null-sinks" = {
  # "context.objects" = [
    # {
      # # A default dummy driver. This handles nodes marked with the "node.always-driver"
      # # properyty when no other driver is currently active. JACK clients need this.
      # factory = "spa-node-factory";
      # args = {
        # "factory.name" = "support.node.driver";
        # "node.name" = "Dummy-Driver";
        # "priority.driver" = 8000;
      # };
    # }
    # {
      # factory = "adapter";
      # args = {
        # "factory.name" = "support.null-audio-sink";
        # "node.name" = "Microphone-Proxy";
        # "node.description" = "Microphone";
        # "media.class" = "Audio/Source/Virtual";
        # "audio.position" = "MONO";
      # };
    # }
    # {
      # factory = "adapter";
      # args = {
        # "factory.name" = "support.null-audio-sink";
        # "node.name" = "Main-Output-Proxy";
        # "node.description" = "Main Output";
        # "media.class" = "Audio/Sink";
        # "audio.position" = "FL,FR";
      # };
    # }
  # ];
# };

# services.pipewire.extraConfig.pipewire-pulse."92-low-latency" = {
  # "context.properties" = [
    # {
      # name = "libpipewire-module-protocol-pulse";
      # args = { };
    # }
  # ];
  # "pulse.properties" = {
    # "pulse.min.req" = "32/48000";
    # "pulse.default.req" = "32/48000";
    # "pulse.max.req" = "32/48000";
    # "pulse.min.quantum" = "32/48000";
    # "pulse.max.quantum" = "32/48000";
  # };
  # "stream.properties" = {
    # "node.latency" = "32/48000";
    # "resample.quality" = 1;
  # };
# };

# services.pipewire.socketActivation = false; 
# Start WirePlumber (with PipeWire) at boot.
# systemd.user.services.wireplumber.wantedBy = [ "default.target" ];

services.xserver.libinput.enable = true;

users.users.asd = {
  isNormalUser = true;
  description = "asd";
  extraGroups = [ "networkmanager" "wheel" "audio" ];
  packages = with pkgs; [
    kdePackages.kate
    # thunderbird
  ];
};

users.users.asd.linger = true;

programs.fish.enable = true;

users.defaultUserShell = pkgs.fish;

programs.firefox.enable = true;

nixpkgs.config.allowUnfree = true;

virtualisation.containers.enable = true;
virtualisation = {
  podman = {
    enable = true;

    # Create a `docker` alias for podman, to use it as a drop-in replacement
    dockerCompat = true;

    # Required for containers under podman-compose to be able to talk to each other.
    defaultNetwork.settings.dns_enabled = true;
  };
};

environment.systemPackages = with pkgs; [
  catppuccin-kde
  acpi
  alacritty
  alsa-utils
  appstream
  aria2
  atuin
  bat
  bottom
  brave
  byobu
  clinfo
  cmake
  curl
  debootstrap
  difftastic
  dive # look into docker image layers
  dnsmasq
  docker-compose # start group of containers for dev
  dust
  emacs30
  fd
  file
  unstable.fish
  nix-ld
  # fishPlugins.done
  # fishPlugins.forgit
  # fishPlugins.fzf-fish
  # fishPlugins.grc
  # fishPlugins.hydro
  unstable.flatpak
  foot
  fuse3
  fzf
  gcc
  gcc14Stdenv
  gdk-pixbuf
  gdm
  git
  glib
  gpgme
  grc
  grub2
  grub2_efi
  gsettings-desktop-schemas
  helix
  htop
  json-glib
  libarchive
  libcap
  libgcc
  librsvg
  libseccomp
  libxml2
  lsd
  lxc
  man-pages
  man-pages-posix
  meson
  miniserve
  mpv
  neovim
  networkmanager-openconnect
  nix-index
  nushell
  openconnect
  openssl
  oxygen
  parted
  pavucontrol
  pciutils
  pkg-config
  podman
  podman-compose # start group of containers for dev
  podman-tui # status of containers in the terminal
  python3
  python3Full
  qbittorrent-enhanced
  rclone
  ripgrep
  ruff
  rustc
  cargo
  (callPackage /root/debMirror.nix {})
  skim
  squashfsTools
  starship
  tmux
  unzip
  uv
  vim
  wayland
  wayland-protocols
  wezterm
  wget
  xorg.libXau
  yazi
  zip
  zoxide
  zstd
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
services.flatpak.enable = true;

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


