{pkgs ? import <nixpkgs> {}}: let
  mylist = with pkgs; [
    cargo
    cargo-zigbuild
    git
    rustc
    zig
  ];
in (pkgs.mkShell {
  name = "good_rust_zig_env";
  packages = mylist;
  runScript = "bash";
})
