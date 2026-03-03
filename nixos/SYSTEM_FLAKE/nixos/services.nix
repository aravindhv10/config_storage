{
  pkgs,
  unstable,
  ...
}: {
  services = {
    displayManager.sessionPackages = [unstable.wayfire];
    chrony.enable = true;
    openssh.enable = true;
    printing.enable = true;
    thermald.enable = true;
    libinput.enable = true;

    nfs = {
      server = {
        enable = true;
        exports = "/home/vm 192.168.122.2(rw,no_root_squash,no_subtree_check)";
      };
    };

    flatpak = {
      enable = true;
      package = unstable.flatpak;
    };

    desktopManager = {
      plasma6.enable = true;
      gnome.enable = true;
    };

    pipewire = {
      enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };

      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    displayManager = {
      gdm.enable = false;
      sddm = {
        enable = false;
        wayland.enable = false;
        settings.General.DisplayServer = "wayland";
      };
    };

    greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "${pkgs.uwsm}/bin/uwsm start ${pkgs.wayfire}/bin/wayfire";
          user = "asd";
        };
        default_session = initial_session;
      };
    };

    dnsmasq = {
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
        local-service = true;
        log-queries = true;
        bogus-priv = true;
        domain-needed = true;
        all-servers = true;
        dnssec = true;
        trust-anchor = ".,20326,8,2,E06D44B80B8F1D39A95C0B0D7C65D08458E880409BBC683457104237C7F8EC8D";
        dhcp-range = ["192.168.122.101,192.168.122.200"];
      };
    };
  };
}
