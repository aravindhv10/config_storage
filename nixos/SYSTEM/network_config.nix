{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  networking = {
    hosts = {
      "192.168.122.2" = ["vm"];
    };

    timeServers = ["ntp.example.com" "time.google.com"];

    networkmanager.enable = true;

    nftables.enable = true;

    firewall.enable = false;

    useDHCP = lib.mkDefault true;
  };
}
