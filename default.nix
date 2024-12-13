{ pkgs ? import
    (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/63dacb46bf939521bdc93981b4cbb7ecb58427a0.tar.gz";
      sha256 = "sha256:1lr1h35prqkd1mkmzriwlpvxcb34kmhc9dnr48gkm8hh089hifmx";
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
        cowsay "Kirnu!"
      '';
    };

    # build derivation
    kirnuBuild = beamPackages.mixRelease rec {
      pname = "kirnu";
      version = "1.0.0";
      src = ./.;
      removeCookie = false;
      mixNixDeps = import ./deps.nix { inherit lib beamPackages; };
    };

    # docker packaging derivation
    docker = pkgs.dockerTools.buildLayeredImage {
      name = "kirnu";
      created = "now";
      config =
        {
          Cmd = [
            "kirnu"
            "start_iex"
          ];
          Env = [
            "ELIXIR_ERL_OPTIONS=+fnu"
            "LC_ALL=C"
            "ERL_AFLAGS='-kernel shell_history enabled'"
          ];
        };

      contents = [
        kirnuBuild
        dockerTools.binSh
      ];
    };



  };
in
packages
