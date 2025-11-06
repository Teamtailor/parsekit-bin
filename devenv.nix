{ pkgs, lib, config, inputs, ... }:

{
  packages = [
    pkgs.clang
    pkgs.cmake
    pkgs.libclang
    pkgs.openssl
  ];

  env = {
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
  };

  languages.ruby.enable = true;
  languages.rust.enable = true;
  languages.c.enable = true;
}
