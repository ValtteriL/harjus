{ pkgs ? import (fetchTarball {
  url =
    "https://github.com/NixOS/nixpkgs/archive/3f0a8ac25fb674611b98089ca3a5dd6480175751.tar.gz";
  sha256 = "sha256:10i7fllqjzq171afzhdf2d9r1pk9irvmq5n55h92rc47vlaabvr4";
}) { config.allowUnfree = true; }, pname ? "fast-quickfix", version ? "latest"
}:

with pkgs;

let

  enableParallelBuilding = true;

  packages = rec {

    fstack = stdenv.mkDerivation {
      pname = "fstack";
      version = "1.24";

      src = fetchFromGitHub {
        owner = "F-Stack";
        repo = "fstack";
        rev = "1.24";
        hash = "sha256-MlqJOoMSRuYeG+jl8DFgcNnpEyeRgDCK2JlN9pOqBWA=";
      };

      nativeBuildInputs = [ cmake ninja pkg-config gawk ];
      buildInputs = [ openssl numactl pcre zlib bc ];

      # Preserve common environment variables used by the project's Makefiles
      # and set a simple install prefix into $out.
      configurePhase = ''
        # nothing to configure at top-level
      '';

      buildPhase = ''
        echo "Building F-Stack: compiling lib/"
        cd lib && PKG_CONFIG_PATH_FOR_TARGET=/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH_FOR_TARGET make
      '';

      installPhase = ''
        echo "Installing F-Stack into $out"
        mkdir -p $out
        pushd lib
        make install PREFIX=$out
        popd
      '';

      meta = with lib; {
        description = "F-Stack user-space TCP/IP stack.";
        homepage = "https://github.com/F-Stack/f-stack";
        license = licenses.mit;
        maintainers = with maintainers; [ ];
      };
    };
  };
in packages
