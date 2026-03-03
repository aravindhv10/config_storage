{lib, ...}: {
  networking = {
    hostName = "nixos";

    hosts = {
      "192.168.122.2" = ["vm"];
    };

    firewall.enable = false;
    networkmanager.enable = true;
    nftables.enable = true;
    timeServers = ["ntp.example.com" "time.google.com"];
    useDHCP = lib.mkDefault true;
  };
}
