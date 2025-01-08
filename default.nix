{ pkgs ? import
    (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/b30f97d8c32d804d2d832ee837d0f1ca0695faa5.tar.gz";
      sha256 = "sha256:11af9sclvfq1477khps9g9anra5x2xnhl7527c99j1ld01wg33jk";
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
      ERL_AFLAGS = "-kernel shell_history enabled";

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
            "ERL_AFLAGS='-kernel shell_history enabled'"
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
