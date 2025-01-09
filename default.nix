{ pkgs ? import
    (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/3f0a8ac25fb674611b98089ca3a5dd6480175751.tar.gz";
      sha256 = "sha256:10i7fllqjzq171afzhdf2d9r1pk9irvmq5n55h92rc47vlaabvr4";
    })
    { }
}:

with pkgs;

let
  packages = rec {

    # The shell of our experiment runtime environment
    devEnv = mkShellNoCC rec {
      name = "devEnv";

      # environment variables
      ELIXIR_ERL_OPTIONS = "+fnu";
      LC_ALL = "C";
      ERL_AFLAGS = "-kernel shell_history enabled -enable-feature maybe_expr";

      # packages to be installed in env
      packages = with pkgs; [
        nixpkgs-fmt
        elixir
        mix2nix
        cowsay
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
      config =
        {
          Cmd = [
            "harjus"
            "start"
          ];
          Env = [
            "ELIXIR_ERL_OPTIONS=+fnu"
            "LC_ALL=C"
            "ERL_AFLAGS='-kernel shell_history enabled -enable-feature maybe_expr'"
          ];
        };

      contents = [
        harjusBuild
        dockerTools.binSh
      ];
    };



  };
in
packages
