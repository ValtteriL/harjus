{ pkgs ? import (fetchTarball {
  url =
    "https://github.com/NixOS/nixpkgs/archive/3f0a8ac25fb674611b98089ca3a5dd6480175751.tar.gz";
  sha256 = "sha256:10i7fllqjzq171afzhdf2d9r1pk9irvmq5n55h92rc47vlaabvr4";
}) { config.allowUnfree = true; } }:

with pkgs;

let

  src = nix-gitignore.gitignoreSource [''
    harjus-port
    deploy
    docs
    test''] ./.;
  version = "1.0.0";
  pname = "harjus";

  mixFodDeps = beamPackages.fetchMixDeps {
    pname = "mix-deps-${pname}";
    inherit src version;
    hash = "sha256-o1ROk8FwQA5DLggx18y3eDVkw2p0BFDrFYmcq/Na0AI=";
  };

  packages = rec {

    # The shell of our experiment runtime environment
    devEnv = mkShell rec {
      name = "devEnv";

      # environment variables
      ELIXIR_ERL_OPTIONS = "+fnu";
      ERL_AFLAGS = "-kernel shell_history enabled -enable-feature maybe_expr";
      PROPCHECK_VERBOSE = "1"; # print exceptions in propcheck
      AWS_PROFILE = "137068223640_AdministratorAccess";

      # packages to be installed in env
      packages = with pkgs; [
        # for working with nix
        glibcLocales
        nixpkgs-fmt
        nixfmt-classic

        # elixir
        elixir
        cowsay

        # C++
        cmake
        ninja
        gdb
        qt6.full

        # deployment
        terraform
        awscli2
      ];

      # this is executed when shell entered
      shellHook = ''
        cowsay "Harjus!"
      '';
    };

    # build derivation
    harjusBuild = beamPackages.mixRelease rec {
      inherit mixFodDeps src version pname;
      removeCookie = false;
    };

    harjusPortBuild = stdenv.mkDerivation {
      inherit version;
      pname = "${pname}-port";

      src = nix-gitignore.gitignoreSource [ ] ./harjus-port;

      buildInputs = [ qt6.qtbase ];
      nativeBuildInputs = [ cmake ninja qt6.wrapQtAppsNoGuiHook ];
    };

    # docker packaging derivation
    docker = pkgs.dockerTools.buildLayeredImage {
      name = "harjus";
      created = "now";
      config = {
        Cmd = [ "harjus" "start" ];
        Env = [
          "ELIXIR_ERL_OPTIONS=+fnu"
          "LC_ALL=C.UTF-8"
          "ERL_AFLAGS='-kernel shell_history enabled -enable-feature maybe_expr'"
        ];
      };

      # Minimize the size by using only runtime dependencies
      contents = [ glibcLocales harjusBuild harjusPortBuild ];
    };

  };
in packages
