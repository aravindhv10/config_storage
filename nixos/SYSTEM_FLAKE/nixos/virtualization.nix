{...}: {
  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
    containers.enable = true;
    incus.enable = true;

    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
