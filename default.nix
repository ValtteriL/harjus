# default.nix
let
  nixpkgs = fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/c2448301fb856e351aab33e64c33a3fc8bcf637d.tar.gz";
    sha256 = "sha256:1rcvx4x6kc652pan6jggpqfvrzydhfi9k3kpjkj55mc38dwl690y";
  };

  pkgs = import nixpkgs {
    config = { allowUnfree = true; };
    overlays = [ ];
  };

in rec {
  run-clang-tidy = pkgs.callPackage ./nix/run-clang-tidy.nix { };
  git-clang-format = pkgs.callPackage ./nix/git-clang-format.nix { };

  devEnv = pkgs.callPackage ./nix/devEnv.nix {
    run-clang-tidy = run-clang-tidy;
    git-clang-format = git-clang-format;
  };
}
