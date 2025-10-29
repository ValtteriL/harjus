{
  stdenv,
  fetchFromGitHub,
  pkg-config,
  gawk,
  openssl,
  numactl,
  pcre,
  zlib,
  bc,
  lib
}:

let
  src = fetchFromGitHub {
    owner = "F-Stack";
    repo = "f-stack";
    rev = "1.24";
    sha256 = "sha256-zsIOQ03q/33VPME12CnMOo79xZRIpETrcZwuEMwyXQ8=";
  };
in

stdenv.mkDerivation {
  pname = "fstack";
  version = "1.24";

  inherit src;

  sourceRoot = "${src.name}/lib";

  nativeBuildInputs = [ pkg-config gawk ];
  buildInputs = [ openssl numactl pcre zlib bc ];
}
