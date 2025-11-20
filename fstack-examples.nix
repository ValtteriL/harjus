{ stdenv, fetchFromGitHub, fstack, pkg-config, gawk, openssl, numactl, pcre
, zlib, bc, lib, libpcap, libnl, libelf, jansson, dpdk }:

let
  src = fetchFromGitHub {
    owner = "F-Stack";
    repo = "f-stack";
    rev = "v1.25";
    sha256 = "sha256-k7GEg3oAr/1qQcXBa6ABIGv4cQ9/i8IRqoGR7AGVLbM=";
  };

in stdenv.mkDerivation {
  pname = "fstack-examples";
  version = "1.25";

  inherit src;

  # Make the fstack library available when building the examples.
  nativeBuildInputs = [ pkg-config gawk dpdk ];
  buildInputs =
    [ openssl numactl pcre zlib bc dpdk libpcap libnl libelf jansson fstack ];

  sourceRoot = "${src.name}/example";

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    cp helloworld $out/bin
    runHook postInstall
  '';
}
