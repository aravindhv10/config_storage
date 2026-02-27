{
  config,
  lib,
  pkgs,
  modulesPath,
  unstable,
  inputs,
  ...
}: {
  environment = {
    etc."greetd/environments".text = ''
      wayfire
      fish
      bash
    '';

    variables = {
      ROC_ENABLE_PRE_VEGA = "1";
      EDITOR = "hx";
      QT_SCALE_FACTOR = "1.25";
    };

    gnome.excludePackages = with pkgs; [
      atomix # puzzle game
      cheese # webcam tool
      epiphany # web browser
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

    systemPackages = with pkgs; [
      acpi
      alsa-utils
      appstream
      azure-cli
      blend2d
      brave
      bridge-utils
      buildah
      cargo
      cargo-info
      catppuccin-kde
      chromium
      clinfo
      cmake
      conky
      curl
      dig
      distrobox
      dive
      dmidecode
      dnsmasq
      docker-compose
      ffmpeg
      ffmpeg.dev
      file
      foot
      fuse3
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
      kdePackages.kolourpaint
      kitty
      libarchive
      libcap
      libgcc
      libinput
      librsvg
      libseccomp
      libxml2
      lldb
      llvmPackages_20.clang
      llvmPackages_20.clang-tools
      lxc
      man-pages
      man-pages-posix
      mate.mate-panel
      mate.mate-panel-with-applets
      mate.mate-session-manager
      meson
      mpv
      networkmanagerapplet
      networkmanager-openconnect
      nh
      nix-index
      nix-ld
      openconnect
      openssl
      parted
      pavucontrol
      pciutils
      pkg-config
      podman
      podman-compose
      podman-tui
      poppler-utils
      qbittorrent-enhanced
      qpdf
      rust-analyzer
      rust-bindgen
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
      virt-viewer
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

      (unstable.python313.withPackages (ps:
        with ps; [
          albumentations
          datafusion
          einops
          fastapi
          flask
          gnumake
          h5py
          inotify-simple
          ipython
          jax
          lightning
          matplotlib
          multiprocess
          numpy
          onnx
          onnxruntime
          opencv-python
          pillow
          protobuf
          python-multipart
          requests
          safetensors
          tensorboard
          tensorboardx
          timm
          torch
          torchmetrics
          torchvision
          transformers
          uvicorn
          yt-dlp
        ]))

      unstable.alacritty
      unstable.alejandra
      unstable.aria2
      unstable.atuin
      unstable.bat
      unstable.bottom
      unstable.brightnessctl
      unstable.byobu
      unstable.clapboard
      unstable.delta
      unstable.difftastic
      unstable.dust
      unstable.emacs30
      unstable.emacs-lsp-booster
      unstable.eza
      unstable.fd
      unstable.fzf
      unstable.gitui
      unstable.helix
      unstable.inkscape
      unstable.lapce
      unstable.lsd
      unstable.lyx
      unstable.mako
      unstable.miniserve
      unstable.mpvpaper
      unstable.neovim
      unstable.nixfmt
      unstable.nushell
      unstable.openblas
      unstable.openblas.dev
      unstable.opencv4
      unstable.pdf2svg
      unstable.procs
      unstable.quickshell
      unstable.rclone
      unstable.ripgrep
      unstable.ruff
      unstable.rustlings
      unstable.skim
      unstable.spice-gtk
      unstable.squashfsTools
      unstable.starship
      unstable.swww
      unstable.television
      unstable.texlab
      unstable.tmux
      unstable.uv
      unstable.wezterm
      unstable.wine
      unstable.wlsunset
      unstable.wluma
      unstable.yazi
      unstable.ydotool
      unstable.zed-editor
      unstable.zoxide

      # Add deb_mirror build here
      inputs.deb_mirror.packages.${pkgs.system}.default

      # Thorium
      inputs.thorium.packages.${pkgs.system}.thorium-avx2 # change avx2 for the version you want to install

      (unstable.gnuplot.override {
        withLua = true;
        withTeXLive = true; # This provides the necessary TikZ support
      })

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

        static char * const args[] = {"thorium", NULL};

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
  };
}
