{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  services = {
    desktopManager = {
      plasma6.enable = true;
      gnome.enable = true;
    };

    # Enable the X11 windowing system.
    # You can disable this if you're only using the Wayland session.
    # xserver = {
    #     enable = true;
    #     videoDrivers = ["amdgpu"];
    # };

    displayManager = {
      gdm.enable = false;
      sddm = {
        enable = false;
        wayland.enable = false;
        settings.General.DisplayServer = "wayland";
      };
    };

    displayManager.sessionPackages = [unstable.wayfire];

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

    chrony.enable = true;
    openssh.enable = true;
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
  };
}
