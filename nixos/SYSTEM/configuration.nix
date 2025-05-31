{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  unstable = import <nixos-unstable> {};
in {
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

      '';
    };
  };

  networking = {
    networkmanager.enable = true;

    nftables.enable = true;

    useDHCP = lib.mkDefault true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "uas" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd" "amdgpu"];
  boot.extraModulePackages = [];

  environment.variables = {
    ROC_ENABLE_PRE_VEGA = "1";

    EDITOR = "hx";

    QT_SCALE_FACTOR = "1.25";
  };

  hardware.graphics.extraPackages = [pkgs.amdvlk pkgs.rocmPackages.clr.icd];

  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  hardware.graphics.enable32Bit = true;
  hardware.graphics.extraPackages32 = [pkgs.driversi686Linux.amdvlk];

  boot.kernelPackages = pkgs.linuxPackages_6_14;

  boot.kernelParams = ["zswap.enabled=1" "zswap.max_pool_percent=80"];

  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "60%";
  };

  networking.hostName = "nixos";

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

  services.xserver = {
    enable = true;
    videoDrivers = ["amdgpu"];
  };

  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.uwsm}/bin/uwsm start ${pkgs.wayfire}/bin/wayfire";

        user = "asd";
      };
      default_session = initial_session;
    };
  };

  environment.etc."greetd/environments".text = ''
    wayfire
    fish
    bash
  '';

  programs.wayfire = {
    enable = true;
    # package = unstable.wayfire;
    plugins = [
      pkgs.wayfirePlugins.firedecor
      pkgs.wayfirePlugins.focus-request
      pkgs.wayfirePlugins.wayfire-plugins-extra
      pkgs.wayfirePlugins.wayfire-shadows
      pkgs.wayfirePlugins.wcm
      pkgs.wayfirePlugins.wf-shell
      pkgs.wayfirePlugins.windecor
      pkgs.wayfirePlugins.wwp-switcher
    ];
  };

  services.displayManager.sessionPackages = [unstable.wayfire];

  services.desktopManager.plasma6.enable = true;

  programs.hyprland = {
    enable = true;
    package = unstable.hyprland;
    withUWSM = true; # recommended for most users
    # withUWSM = false; # recommended for most users
    xwayland.enable = true; # Xwayland can be disabled.
  };

  services.xserver.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    atomix # puzzle game
    cheese # webcam tool
    epiphany # web browser
    evince # document viewer
    geary # email reader
    gedit # text editor
    gnome-characters
    gnome-music
    gnome-photos
    gnome-terminal
    gnome-tour
    hitori # sudoku game
    iagno # go game
    tali # poker game
    totem # video player
    seahorse
  ];

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = true;
  };

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

  services.libinput.enable = true;

  users.users.asd = {
    isNormalUser = true;
    shell = unstable.fish;
    description = "asd";
    extraGroups = ["networkmanager" "wheel" "audio" "incus-admin" "libvirtd"];
    packages = with pkgs; [
      kdePackages.kate
      # thunderbird
    ];
  };

  users.defaultUserShell = pkgs.zsh;

  programs.zsh = {
    enable = true;

    ohMyZsh = {
      enable = true;
      plugins = ["git" "starship" "zoxide"];
      theme = "robbyrussell";
    };
  };

  programs.fish = {
    enable = true;
    package = unstable.fish;
  };

  services.thermald.enable = true;

  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;

  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = ["asd"];

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

  environment.systemPackages = with pkgs; [
    acpi
    alsa-utils
    appstream
    brave
    brightnessctl
    cargo
    catppuccin-kde
    clang_19
    clang-tools_19
    clinfo
    cmake
    curl
    dig
    distrobox
    dive # look into docker image layers
    dmidecode
    dnsmasq
    docker-compose # start group of containers for dev
    ffmpeg
    file
    foot
    fuse3
    fzf
    gcc
    gcc14Stdenv
    gdk-pixbuf
    gdm
    git
    git-lfs
    glib
    gpgme
    graphicsmagick-imagemagick-compat
    grc
    grim
    grub2
    grub2_efi
    gsettings-desktop-schemas
    jq
    json-glib
    kitty
    libarchive
    libcap
    libgcc
    libinput
    librsvg
    libseccomp
    libxml2
    lxc
    man-pages
    man-pages-posix
    meson
    neovim
    networkmanagerapplet
    networkmanager-openconnect
    nh
    nix-index
    nix-ld
    nm-tray
    nushell
    openconnect
    openssl
    parted
    pavucontrol
    pciutils
    pkg-config
    podman
    podman-compose # start group of containers for dev
    podman-tui # status of containers in the terminal
    qbittorrent-enhanced
    rustc
    rustfmt
    shellcheck
    swayosd
    texliveFull
    thunderbird
    tree
    unzip
    uwsm
    vim
    vscode-fhs
    waybar
    wayland
    wayland-protocols
    wf-recorder
    wget
    wl-clipboard
    wlogout
    zip
    zstd

    (pkgs.python312.withPackages (ps:
      with ps; [
        ipython
        numpy
        opencv-python
        requests
        torch
        torchvision
        yt-dlp
      ]))

    rocmPackages.hipblas
    rocmPackages.hipcc

    unstable.ags
    unstable.alacritty
    unstable.alejandra
    unstable.aria2
    unstable.atuin
    unstable.azure-cli
    unstable.bat
    unstable.bottom
    unstable.byobu
    unstable.clapboard
    unstable.difftastic
    unstable.dust
    unstable.emacs30
    unstable.fd
    unstable.helix
    unstable.inkscape
    unstable.ironbar
    unstable.kickoff
    unstable.lapce
    unstable.lsd
    unstable.lyx
    unstable.mako
    unstable.miniserve
    unstable.mpv
    unstable.mpvpaper
    unstable.nixfmt-rfc-style
    unstable.pdf2svg
    unstable.rclone
    unstable.ripgrep
    unstable.ruff
    unstable.rust-analyzer
    unstable.skim
    unstable.squashfsTools
    unstable.starship
    unstable.swww
    unstable.tmux
    unstable.tofi
    unstable.uv
    unstable.wezterm
    unstable.wine
    unstable.wldash
    unstable.wlsunset
    unstable.wluma
    unstable.yazi
    unstable.ydotool
    unstable.yofi
    unstable.zed-editor
    unstable.zoxide

    (callPackage /root/debMirror.nix {})

    (writeCBin "YDOTOOL_DAEMON" ''

      #include <stdio.h>
      #include <stdlib.h>
      #include <string.h>
      #include <unistd.h>

      #define SIZE_BUFFER (1 << 20)

      static char BUFFER[SIZE_BUFFER];
      static int BUFFER_CURRENT;
      static char SUDO_ASKPASS[] = "/SUDO_ASKPASS";

      static char sudo[] = "sudo";
      static char minus_b[] = "-b";
      static char minus_E[] = "-E";
      static char minus_A[] = "-A";
      static char prog[] = "ydotoold";
      static char *args[7];

      static inline size_t align(size_t const val) {
        size_t const newval = val & (~7);
        return newval == val ? val : newval + 8;
      }

      static inline char *myalloc(size_t const insize) {
        BUFFER_CURRENT = align(BUFFER_CURRENT);
        char *ret = BUFFER + BUFFER_CURRENT;
        BUFFER_CURRENT += align(insize);
        return ret;
      }

      static inline char *get_sudo_askpass() {
        char *HOME = getenv("HOME");
        size_t len_HOME = strlen(/*const char *s =*/HOME);
        char *ret = myalloc(/*size_t const insize =*/len_HOME + sizeof(SUDO_ASKPASS));

        /*void **/ memcpy(/*void dest[restrict .n] =*/ret,
                          /*const void src[restrict .n] =*/HOME,
                          /*size_t n =*/len_HOME);

        /*void **/ memcpy(/*void dest[restrict .n] =*/ret + len_HOME,
                          /*const void src[restrict .n] =*/SUDO_ASKPASS,
                          /*size_t n =*/sizeof(SUDO_ASKPASS));

        return ret;
      }

      static inline char *get_ydotool_args() {
        uid_t const uid = getuid();
        gid_t const gid = getgid();
        /*static inline*/ char *buf = myalloc(/*size_t const insize =*/128);
        sprintf(buf, "--socket-own=%d:%d", uid, gid);
        return buf;
      }

      int main() {
        char *final_sudo_askpass = get_sudo_askpass();
        /*int*/ setenv(/*const char *name =*/"SUDO_ASKPASS",
                       /*const char *value =*/final_sudo_askpass,
                       /*int overwrite =*/1);

        unsigned char i = 0;
        args[i] = sudo;
        ++i;
        // args[i] = minus_b;
        // ++i;
        args[i] = minus_E;
        ++i;
        args[i] = minus_A;
        ++i;
        args[i] = prog;
        ++i;
        args[i] = get_ydotool_args();
        ++i;
        args[i] = NULL;
        ++i;

        /*int*/ execvp(args[0], args);

        return 0;
      }

    '')

    (writeCBin "M_PLUS" ''

      #include <unistd.h>

      static char *const args[] = {"ydotool", "mousemove", "-w", "--",
                                   "0",       "2",         NULL};

      int main() {
        int ret = execvp(args[0], args);
        return ret;
      }

    '')

    (writeCBin "M_MINUS" ''

      #include <unistd.h>

      static char *const args[] = {"ydotool", "mousemove", "-w", "--",
                                   "0",       "-2",         NULL};

      int main() {
        int ret = execvp(args[0], args);
        return ret;
      }

    '')

    (writeCBin "M_C_PLUS" ''

      #include <unistd.h>

      static char *const args[] = {"swayosd-client", "--brightness=raise", NULL};

      int main() {
        int ret = execvp(args[0], args);
        return ret;
      }

    '')

    (writeCBin "M_C_MINUS" ''

      #include <unistd.h>

      static char *const args[] = {"swayosd-client", "--brightness=lower", NULL};

      int main() {
        int ret = execvp(args[0], args);
        return ret;
      }

    '')

    (writeCBin "M_C_LEFTBRACE" ''

      #include <unistd.h>

      static char *const args[] = {"swayosd-client", "--max-volume=255", "--output-volume=-10", NULL};

      int main() {
        int ret = execvp(args[0], args);
        return ret;
      }

    '')

    (writeCBin "M_C_RIGHTBRACE" ''

      #include <unistd.h>

      static char *const args[] = {"swayosd-client", "--max-volume=255", "--output-volume=+10", NULL};

      int main() {
        int ret = execvp(args[0], args);
        return ret;
      }

    '')

    (writeCBin "M_C_ESC" ''

      #include <unistd.h>

      static char * const args[] = {"wlogout", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_F1" ''

      #include <unistd.h>

      static char * const args[] = {"alacritty", "msg", "create-window", "-e", "byobu-tmux", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_F2" ''

      #include <unistd.h>

      static char * const args[] = {"alacritty", "msg", "create-window", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_F3" ''

      #include <unistd.h>

      static char * const args[] = {"emacsclient", "-c", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_C_1" ''

      #include <unistd.h>
      #include <sys/wait.h>

      int start (char * const * argv) {
          int ret = execvp(argv[0], argv);
          return ret;
      }

      int do_start (char * const * argv) {
          pid_t p_start;
          int ret_start;
          p_start = fork();
          if(p_start == 0){
              ret_start = start (argv);
              return ret_start;
          }
          waitpid(p_start, NULL, 0);
          return 0;
      }

      static char * const args[] = {"emacs", NULL};

      int main () {
          do_start(args);
          return 0;
      }

    '')

    (writeCBin "M_C_2" ''

      #include <unistd.h>

      static char * const args[] = {"emacsclient", "-c", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "TY" ''

      #include <unistd.h>
      #include <sys/wait.h>

      int start (char * const * argv) {
          int ret = execvp(argv[0], argv);
          return ret;
      }

      int do_start (char * const * argv) {
          pid_t p_start;
          int ret_start;
          p_start = fork();
          if(p_start == 0){
              ret_start = start (argv);
              return ret_start;
          }
          waitpid(p_start, NULL, 0);
          return 0;
      }

      static char * const args[] = {"byobu-tmux", NULL};

      int main () {
          do_start(args);
          return 0;
      }

    '')

    (writeCBin "enter_emacs_flatpak" ''

      #include <unistd.h>

      static char * const args[] = {"flatpak", "run", "--command=bash", "org.gnu.emacs", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_C_Q" ''

      #include <unistd.h>

      static char * const args[] = {"wezterm", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_C_W" ''

      #include <unistd.h>

      static char * const args[] = {"alacritty" , "msg" , "create-window" , "-e" , "byobu-tmux" , NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_C_E" ''

      #include <unistd.h>

      static char * const args[] = {"alacritty" , "msg" , "create-window" , "-e" , "enter_emacs_flatpak" , NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_C_R" ''

      #include <unistd.h>

      static char * const args[] = {"footclient" , "-e" , "enter_emacs_flatpak" , NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_C_T" ''

      #include <unistd.h>
      #include <sys/wait.h>

      int foot_server () {
          static char * const args[] = {"foot" , "-s" , NULL};
          int ret = execvp(args[0], args);
          return ret;
      }

      int alacritty_server () {
          static char * const args[] = {"alacritty" , "-e" , "TY" , NULL};
          int ret = execvp(args[0], args);
          return ret;
      }

      int both () {
          pid_t p_foot;
          pid_t p_alacritty;
          int ret_foot;
          int ret_alacritty;

          p_foot = fork();
          if(p_foot == 0){
              ret_foot = foot_server ();
              return ret_foot;
          }

          p_alacritty = fork();
          if(p_alacritty == 0){
              ret_alacritty = alacritty_server ();
              return ret_alacritty;
          }

          waitpid(p_foot, NULL, 0);
          waitpid(p_alacritty, NULL, 0);

          return 0;
      }

      int main () {
          both();
          return 0;
      }

    '')

    (writeCBin "M_C_A" ''

      #include <unistd.h>

      static char * const args[] = {"firefox" ,  NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_C_S" ''

      #include <unistd.h>

      static char * const args[] = {"brave" , NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_C_D" ''

      #include <unistd.h>

      static char * const args[] = {"dolphin" , NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_C_F" ''

      #include <unistd.h>

      static char * const args[] = {"pavucontrol" , NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_C_G" ''

      #include <unistd.h>

      static char * const args[] = {"footclient", "nmtui" , NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_Q" ''

      #include <unistd.h>

      static char * const args[] = {"amixer", "set", "Master,0", "0%", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_W" ''

      #include <unistd.h>

      static char * const args[] = {"amixer", "set", "Master,0", "11%", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_E" ''

      #include <unistd.h>

      static char * const args[] = {"amixer", "set", "Master,0", "22%", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_R" ''

      #include <unistd.h>

      static char * const args[] = {"amixer", "set", "Master,0", "33%", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_T" ''

      #include <unistd.h>

      static char * const args[] = {"amixer", "set", "Master,0", "44%", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_Y" ''

      #include <unistd.h>

      static char * const args[] = {"amixer", "set", "Master,0", "55%", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_U" ''

      #include <unistd.h>

      static char * const args[] = {"amixer", "set", "Master,0", "66%", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_I" ''

      #include <unistd.h>

      static char * const args[] = {"amixer", "set", "Master,0", "77%", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_O" ''

      #include <unistd.h>

      static char * const args[] = {"amixer", "set", "Master,0", "88%", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_P" ''

      #include <unistd.h>

      static char * const args[] = {"amixer", "set", "Master,0", "100%", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_GRAVE" ''

      #include <unistd.h>

      // static char * const args[] = {"brightnessctl", "set", "0%", NULL};
      static char * const args[] = {"swayosd-client", "--brightness=0", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_1" ''

      #include <unistd.h>

      // static char * const args[] = {"brightnessctl", "set", "10%", NULL};
      static char * const args[] = {"swayosd-client", "--brightness=10", NULL};


      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_2" ''

      #include <unistd.h>

      // static char * const args[] = {"brightnessctl", "set", "20%", NULL};
      static char * const args[] = {"swayosd-client", "--brightness=20", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_3" ''

      #include <unistd.h>

      // static char * const args[] = {"brightnessctl", "set", "30%", NULL};
      static char * const args[] = {"swayosd-client", "--brightness=30", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_4" ''

      #include <unistd.h>

      // static char * const args[] = {"brightnessctl", "set", "40%", NULL};
      static char * const args[] = {"swayosd-client", "--brightness=40", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_5" ''

      #include <unistd.h>

      // static char * const args[] = {"brightnessctl", "set", "50%", NULL};
      static char * const args[] = {"swayosd-client", "--brightness=50", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_6" ''

      #include <unistd.h>

      // static char * const args[] = {"brightnessctl", "set", "60%", NULL};
      static char * const args[] = {"swayosd-client", "--brightness=60", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_7" ''

      #include <unistd.h>

      // static char * const args[] = {"brightnessctl", "set", "70%", NULL};
      static char * const args[] = {"swayosd-client", "--brightness=70", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_8" ''

      #include <unistd.h>

      // static char * const args[] = {"brightnessctl", "set", "80%", NULL};
      static char * const args[] = {"swayosd-client", "--brightness=80", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_9" ''

      #include <unistd.h>

      // static char * const args[] = {"brightnessctl", "set", "90%", NULL};
      static char * const args[] = {"swayosd-client", "--brightness=90", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')

    (writeCBin "M_A_0" ''

      #include <unistd.h>

      // static char * const args[] = {"brightnessctl", "set", "100%", NULL};
      static char * const args[] = {"swayosd-client", "--brightness=100", NULL};

      int main () {
          int ret = execvp(args[0], args);
          return ret;
      }

    '')
  ];

  services.openssh.enable = true;

  services.flatpak = {
    enable = true;
    package = unstable.flatpak;
  };

  services.dnsmasq = {
    enable = true;

    alwaysKeepRunning = true;

    resolveLocalQueries = true;

    settings = {
      server = [
        "1.0.0.1"
        "1.1.1.1"
        "149.112.112.112"
        "185.228.168.9"
        "185.228.169.9"
        "192.168.1.254"
        "208.67.220.220"
        "208.67.222.222"
        "4.2.2.2"
        "76.223.122.150"
        "76.76.10.0"
        "76.76.19.19"
        "76.76.2.0"
        "8.8.4.4"
        "8.8.8.4"
        "8.8.8.8"
        "94.140.14.14"
        "94.140.15.15"
        "9.9.9.9"
      ];

      local-service = true; # Accept DNS queries only from hosts whose address is on a local subnet
      log-queries = true; # Log results of all DNS queries
      bogus-priv = true; # Don't forward requests for the local address ranges (192.168.x.x etc) to upstream nameservers
      domain-needed = true; # Don't forward requests without dots or domain parts to upstream nameservers
      all-servers = true;
      dnssec = true; # Enable DNSSEC
      # DNSSEC trust anchor. Source: https://data.iana.org/root-anchors/root-anchors.xml
      trust-anchor = ".,20326,8,2,E06D44B80B8F1D39A95C0B0D7C65D08458E880409BBC683457104237C7F8EC8D";
      dhcp-range = ["192.168.122.101,192.168.122.200"];
    };
  };

  system.stateVersion = "24.11";
}
