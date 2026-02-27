{
  description = "NixOS Flake Configuration";

  inputs = {
    # Standard NixOS stable channel
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # Unstable channel for bleeding edge packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    deb_mirror.url = "github:aravindhv10/deb_mirror";

    # Thorium browser
    thorium.url = "github:Rishabh5321/thorium_flake";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    # Define unstable for use in modules
    unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      # specialArgs allows you to pass variables to all imported modules
      specialArgs = {inherit inputs unstable;};
      modules = [
        ./configuration.nix
      ];
    };
  };
}
