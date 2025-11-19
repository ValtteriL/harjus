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
  fstack = pkgs.callPackage ./fstack.nix { };
  fstack-examples = pkgs.callPackage ./fstack-examples.nix { fstack = fstack; };
  fstack-mt = pkgs.callPackage ./fstack-mt.nix { fstack = fstack; };
  fstack-tools = pkgs.callPackage ./fstack-tools.nix { fstack = fstack; };
  run-clang-tidy = pkgs.callPackage ./run-clang-tidy.nix { };
  git-clang-format = pkgs.callPackage ./git-clang-format.nix { };
  devshell = pkgs.callPackage ./devshell.nix {
    fstack = fstack;
    fstack-examples = fstack-examples;
    fstack-mt = fstack-mt;
    fstack-tools = fstack-tools;
    run-clang-tidy = run-clang-tidy;
    git-clang-format = git-clang-format;
  };
}
