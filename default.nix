{ pkgs ? import (fetchTarball {
  url =
    "https://github.com/NixOS/nixpkgs/archive/3f0a8ac25fb674611b98089ca3a5dd6480175751.tar.gz";
  sha256 = "sha256:10i7fllqjzq171afzhdf2d9r1pk9irvmq5n55h92rc47vlaabvr4";
}) { config.allowUnfree = true; } }:

with pkgs;

let

  version = "1.0.0";
  pname = "harjus";

  packages = rec {

    # build quickfix properly with SSL support
    myQuickfix = stdenv.mkDerivation {
      pname = "quickfix";
      version = "1.15.1";

      src = fetchFromGitHub {
        owner = "quickfix";
        repo = "quickfix";
        rev = "v${version}";
        sha256 = "1fgpwgvyw992mbiawgza34427aakn5zrik3sjld0i924a9d17qwg";
      };

      patches = [
        # Improved C++17 compatibility
        (fetchpatch {
          url =
            "https://github.com/quickfix/quickfix/commit/a46708090444826c5f46a5dbf2ba4b069b413c58.diff";
          sha256 = "1wlk4j0wmck0zm6a70g3nrnq8fz0id7wnyxn81f7w048061ldhyd";
        })
        ./quickfix/00001-fix-build.patch
        ./quickfix/fix_wsl_symlink_error.patch
      ];

      # enable SSL
      cmakeFlags = [ "-DHAVE_SSL=ON" ];

      nativeBuildInputs = [ cmake ninja ];
      buildInputs = [ openssl ];
      enableParallelBuilding = true;
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
        myQuickfix

        # deployment
        terraform
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
        cowsay "Harjus!"
      '';
    };

    # build derivation
    harjusBuild = stdenv.mkDerivation {
      inherit version pname;

      src = nix-gitignore.gitignoreSource [''
        deploy
        docs
        quickfix
        scripts
        .vscode
      ''] ./.;

      buildInputs =
        [ gtest boost openssl libcpr pkg-config libsodium myQuickfix ];
      nativeBuildInputs = [ cmake ninja pkg-config ];
    };

    # docker packaging derivation
    docker = pkgs.dockerTools.buildLayeredImage {
      name = "harjus";
      fromImage = pkgs.dockerTools.pullImage {
        imageName = "library/alpine";
        imageDigest =
          "sha256:1c4eef651f65e2f7daee7ee785882ac164b02b78fb74503052a26dc061c90474";
        finalImageName = "alpine";
        finalImageTag = "3.21.3";
        sha256 = "sha256-BLd0y9w1FIBJO5o4Nu5Wuv9dtGhgvh+gysULwnR9lOo=";
      };
      created = "now";
      config = {
        Cmd = [ "harjus" ];
        Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
      };

      # Minimize the size by using only runtime dependencies
      contents = [ glibcLocales harjusBuild cacert ];
    };

  };
in packages
