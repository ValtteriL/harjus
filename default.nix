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

    # the derivation for kirnu

    test = beamPackages.mixRelease rec {
      pname = "kirnu";
      version = "1.0.0";
      src = ./.;
      removeCookie = false;
      mixNixDeps = import ./deps.nix { inherit lib beamPackages; };
    };

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



  };
in
packages
