{pkgs ? import <nixpkgs> {}}: let
  mylist = with pkgs; [
    rustc
    cargo
    cargo-zigbuild
    zig
    rust-std-rustc
  ];
in (pkgs.mkShell {
  name = "good_rust_zig_env";
  packages = mylist;
  runScript = "bash";
})
