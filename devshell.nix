{ pkgs, fstack, fstack-examples }:

let

in pkgs.mkShell {

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
    clang-tools

    # f-stack
    fstack
    fstack-examples
  ];
}
