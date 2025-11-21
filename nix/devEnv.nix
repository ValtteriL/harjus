{ pkgs, myQuickfix, runClangTidy }:

let

  buildInputs = with pkgs; [
        # for working with nix
        glibcLocales
        nixpkgs-fmt
        nixfmt-classic

        # C++
        cmake
        ninja
        gdb
        clang-tools
        ccache
        gtest
        boost
        openssl
        libcpr
        pkg-config
        libsodium
        gmp
        myQuickfix
        runClangTidy

        # deployment
        terraform
        ansible
        ansible-lint
        awscli2
        python3
        python3Packages.boto3
        python3Packages.botocore
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
      '';
}
