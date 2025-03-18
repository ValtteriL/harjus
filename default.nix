{ pkgs ? import (fetchTarball {
  url =
    "https://github.com/NixOS/nixpkgs/archive/3f0a8ac25fb674611b98089ca3a5dd6480175751.tar.gz";
  sha256 = "sha256:10i7fllqjzq171afzhdf2d9r1pk9irvmq5n55h92rc47vlaabvr4";
}) { config.allowUnfree = true; } }:

with pkgs;

let
  packages = rec {

    # The shell of our experiment runtime environment
    devEnv = mkShell rec {
      name = "devEnv";

      # environment variables
      ELIXIR_ERL_OPTIONS = "+fnu";
      LC_ALL = "C";
      ERL_AFLAGS = "-kernel shell_history enabled -enable-feature maybe_expr";
      PROPCHECK_VERBOSE = "1"; # print exceptions in propcheck
      AWS_PROFILE = "137068223640_AdministratorAccess";

      # packages to be installed in env
      packages = with pkgs; [
        # for working with nix
        nixpkgs-fmt
        nixfmt

        # elixir
        elixir
        mix2nix
        cowsay

        # C++
        cmake

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
      pname = "harjus";
      version = "1.0.0";
      src = ./.;
      removeCookie = false;
      mixNixDeps = import ./deps.nix { inherit lib beamPackages; };
    };

    # docker packaging derivation
    docker = pkgs.dockerTools.buildLayeredImage {
      name = "harjus";
      created = "now";
      config = {
        Cmd = [ "harjus" "start" ];
        Env = [
          "ELIXIR_ERL_OPTIONS=+fnu"
          "LC_ALL=C"
          "ERL_AFLAGS='-kernel shell_history enabled -enable-feature maybe_expr'"
        ];
      };

      contents = [ harjusBuild dockerTools.binSh ];
    };

  };
in packages
