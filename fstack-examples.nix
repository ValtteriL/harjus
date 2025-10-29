{
  stdenv,
  fetchFromGitHub,
  fstack,
  pkg-config,
  numactl,
  openssl
}:

let
  src = fetchFromGitHub {
    owner = "F-Stack";
    repo = "f-stack";
    rev = "1.24";
    sha256 = "sha256-zsIOQ03q/33VPME12CnMOo79xZRIpETrcZwuEMwyXQ8=";
  };

  # commit where dpdk is at version 22.11.1 (close to the f-stack 1.24 supported 22.11.6)
  pinnedNixpkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/203e5461b25add434893bee7ba8bdfeeffffebf0.tar.gz";
    sha256 = "sha256:1b5gcaxl461pbiawcyqh5zh6smlp25sbm00d9cla9il4rd928jyp";
  }) {};

in

stdenv.mkDerivation {
  pname = "fstack-examples";
  version = "1.24";

  inherit src;

  # Make the fstack library available when building the examples.
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ fstack pinnedNixpkgs.dpdk numactl openssl ];

  sourceRoot = "${src.name}/example";
}
