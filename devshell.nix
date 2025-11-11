{ pkgs, fstack, fstack-examples, fstack-mt, fstack-tools, run-clang-tidy }:

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
    clang-tools

    # f-stack
    fstack
    fstack-examples
    fstack-mt
    fstack-tools

    # code quality
    run-clang-tidy
  ];

  nativeBuildInputs = [ pkgs.pkg-config ];

  shellHook = ''
    export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/lib/x86_64-linux-gnu/pkgconfig"
  '';
}
