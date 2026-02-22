{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  networking = {
    # Define your hostname.
    hostName = "nixos";

    hosts = {
      "192.168.122.2" = ["vm"];
    };

    firewall.enable = false;
    networkmanager.enable = true;
    nftables.enable = true;
    timeServers = ["ntp.example.com" "time.google.com"];
    useDHCP = lib.mkDefault true;

    # interfaces.wlp1s0.useDHCP = lib.mkDefault true;
    # wireless.enable = true;
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";
    # firewall.allowedTCPPorts = [ ... ];
    # firewall.allowedUDPPorts = [ ... ];
  };
}
