{ pkgs, fstack, fstack-examples, fstack-mt, fstack-tools, run-clang-tidy
, git-clang-format }:

let
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
    llvmPackages_21.clang-tools

    # f-stack
    fstack
    fstack-examples
    fstack-mt
    fstack-tools

    # code quality
    run-clang-tidy
    git-clang-format
  ];
in pkgs.mkShell {

  inherit buildInputs;

  nativeBuildInputs = [ pkgs.pkg-config ];

  shellHook = ''
    export LD_LIBRARY_PATH="${
      pkgs.lib.makeLibraryPath buildInputs
    }:$LD_LIBRARY_PATH"
  '';
}
