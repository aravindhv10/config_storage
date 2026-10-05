{pkgs ? import <nixpkgs> {}}: let
  mylist = with pkgs; [
    cargo
    cargo-zigbuild
    git
    rustc
    rustup
    zig
  ];
in (pkgs.mkShell {
  name = "good_rust_zig_env";
  packages = mylist;
  runScript = "ls";
})
