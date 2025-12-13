{ pkgs, run-clang-tidy, git-clang-format }:

let

  buildInputs = with pkgs; [
    # for working with nix
    glibcLocales
    nixpkgs-fmt
    nixfmt-classic

    # interfacing
    just

    # C++
    git
    gcc
    cmake
    ninja
    gdb
    ccache
    pkg-config
    dpdk
    bc
    gawk
    libbsd
    llvmPackages_21.clang-tools

    # deployment
    terraform
    awscli2
    uv

    # code quality
    run-clang-tidy
    git-clang-format
  ];
in pkgs.mkShell {

  # disable hardenings (for better debugging experience)
  hardeningDisable = [ "all" ];

  inherit buildInputs;

  # this is executed when shell entered
  shellHook = ''
    export USE_CCACHE=1
    export CCACHE_COMPRESS=1
    export CCACHE_MAXSIZE=10G

    export LD_LIBRARY_PATH="${
      pkgs.lib.makeLibraryPath buildInputs
    }:$LD_LIBRARY_PATH"
  '';

  nativeBuildInputs = [ pkgs.pkg-config ];
}
