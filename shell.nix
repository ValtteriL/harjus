{ pkgs ? import (fetchTarball {
  url =
    "https://github.com/NixOS/nixpkgs/archive/3f0a8ac25fb674611b98089ca3a5dd6480175751.tar.gz";
  sha256 = "sha256:10i7fllqjzq171afzhdf2d9r1pk9irvmq5n55h92rc47vlaabvr4";
}) { config.allowUnfree = true; } }:

pkgs.mkShell {

  buildInputs = with pkgs; [

    # for working with nix
    nixpkgs-fmt
    nixfmt-classic

    # dev
    just

    git
    gcc
    openssl
    bc
    pcre
    zlib
    numactl
    gawk
    libbsd

    cmake
    ninja
    pkg-config

  ];

  shellHook = ''
    export KERNEL_DIR="${pkgs.linux_6_6.dev}/lib/modules/${pkgs.linux_6_6.modDirVersion}/build"
  '';

}

