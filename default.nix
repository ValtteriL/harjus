{ pkgs ? import (fetchTarball {
  url =
    "https://github.com/NixOS/nixpkgs/archive/3f0a8ac25fb674611b98089ca3a5dd6480175751.tar.gz";
  sha256 = "sha256:10i7fllqjzq171afzhdf2d9r1pk9irvmq5n55h92rc47vlaabvr4";
}) { config.allowUnfree = true; }, pname ? "harjus", version ? "latest" }:

with pkgs;

let

  gccFlags =
    "-O3 -march=icelake-server -mtune=icelake-server -pipe -fsemantic-interposition";

  enableParallelBuilding = true;

  # disable performance affecting hardenings
  hardeningDisable =
    [ "fortify" "stackprotector" "pic" "pie" "relro" "bindnow" ];

  packages = rec {

    # build quickfix properly with SSL support
    myQuickfix = stdenv.mkDerivation {
      pname = "quickfix";
      version = "1.16.0";

      src = fetchFromGitHub {
        owner = "quickfix";
        repo = "quickfix";
        rev =
          "92c85ca63fc260d16e24e0ece419ecdec9ffe868"; # 1.16.0 (no release for this commit)
        hash = "sha256-uw47OvhD25rdJaufdgrefotcjyjn/RxT64WNnm2GHmE=";
      };

      patches = [
        # Improved C++17 compatibility
        (fetchpatch {
          url =
            "https://patch-diff.githubusercontent.com/raw/quickfix/quickfix/pull/625.diff";
          hash = "sha256-J4Sw7lPS6gv9gkSn3kAM8RTdoBvpgLeOR4qeXtkjVao=";
        })
        ./quickfix/00001-fix-build.patch
      ];

      # enable SSL
      cmakeFlags =
        [ "-DHAVE_SSL=ON" "-DQUICKFIX_EXAMPLES=OFF" "-DQUICKFIX_TESTS=OFF" ];

      nativeBuildInputs = [ cmake ninja ];
      buildInputs = [ openssl ];

      inherit enableParallelBuilding;
      inherit hardeningDisable;

      NIX_CFLAGS_COMPILE = gccFlags;
    };

    # The shell of our experiment runtime environment
    devEnv = mkShell rec {
      name = "devEnv";

      # packages to be installed in env
      packages = with pkgs; [
        # for working with nix
        glibcLocales
        nixpkgs-fmt
        nixfmt-classic
        cowsay

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

        # deployment
        terraform
        ansible
        ansible-lint
        awscli2
        python3
        python3Packages.boto3
        python3Packages.botocore
      ];

      # disable hardenings (for better debugging experience)
      hardeningDisable = [ "all" ];

      # this is executed when shell entered
      shellHook = ''
        export USE_CCACHE=1
        export CCACHE_COMPRESS=1
        export CCACHE_MAXSIZE=10G
        cowsay "Harjus!"
      '';
    };

    # build derivation
    # this is the main build derivation that will be used to build harjus
    harjusbuild = stdenv.mkDerivation {
      pname = "harjusbuild";
      version = "rolling";

      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [ ./src ./CMakeLists.txt ./include ];
      };

      buildInputs =
        [ gtest boost openssl libcpr pkg-config libsodium gmp myQuickfix ];
      nativeBuildInputs = [ cmake ninja pkg-config ];

      cmakeFlags = [ "-DHARJUS_TESTS=OFF" ];

      inherit enableParallelBuilding;
      inherit hardeningDisable;

      NIX_CFLAGS_COMPILE = gccFlags;
    };

    # harjus wrapper
    # this is the main package that will be used by users
    # it will depend on harjusbuild and provide the executable
    harjus = stdenv.mkDerivation {
      inherit version pname;
      src = harjusbuild.src;
      buildInputs = [ harjusbuild ];
      installPhase = ''
        mkdir -p $out/bin
        ln -s ${harjusbuild}/bin/harjus $out/bin/harjus
        echo "Harjus version ${version} installed successfully!" > $out/version.txt
      '';
    };
  };
in packages
