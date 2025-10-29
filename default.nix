# default.nix
let
  nixpkgs = fetchTarball {
    url =
    "https://github.com/NixOS/nixpkgs/archive/3f0a8ac25fb674611b98089ca3a5dd6480175751.tar.gz";
    sha256 = "sha256:10i7fllqjzq171afzhdf2d9r1pk9irvmq5n55h92rc47vlaabvr4";
  };
  pkgs = import nixpkgs { config = {allowUnfree = true;}; overlays = []; };
in
{
  fstack = pkgs.callPackage ./fstack.nix { };
}