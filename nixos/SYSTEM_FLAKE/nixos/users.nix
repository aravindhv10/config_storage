{
  pkgs,
  unstable,
  ...
}: {
  users = {
    defaultUserShell = pkgs.zsh;
    groups.libvirtd.members = ["asd"];

    users.asd = {
      description = "asd";
      isNormalUser = true;
      shell = unstable.fish;
      packages = [];

      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "incus-admin"
        "libvirtd"
      ];
    };
  };
}
