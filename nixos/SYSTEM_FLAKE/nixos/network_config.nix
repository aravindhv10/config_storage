{lib, ...}: {
  networking = {
    hostName = "nixos";
    firewall.enable = false;
    networkmanager.enable = true;
    nftables.enable = true;
    useDHCP = lib.mkDefault true;

    hosts = {
      "192.168.122.2" = ["vm"];
    };

    timeServers = [
      "ntp.example.com"
      "time.google.com"
    ];
  };
}
