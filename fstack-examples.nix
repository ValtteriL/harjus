{ stdenv, fetchFromGitHub, fstack, pkg-config, gawk, openssl, numactl, pcre
, zlib, bc, lib, libpcap, libnl, libelf, jansson }:

let
  src = fetchFromGitHub {
    owner = "F-Stack";
    repo = "f-stack";
    rev = "v1.25";
    sha256 = "sha256-k7GEg3oAr/1qQcXBa6ABIGv4cQ9/i8IRqoGR7AGVLbM=";
  };

  # commit where dpdk is at version 23.11 (close to the f-stack 1.25 supported 23.11.5)
  pinnedNixpkgs = import (fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/571c71e6f73af34a229414f51585738894211408.tar.gz";
    sha256 = "sha256:0fgp5sqfmh5zgx75rs5101ywkz0fkjff67abms0kc8hyaxmlc7js";
  }) { };

in stdenv.mkDerivation {
  pname = "fstack-examples";
  version = "1.25";

  inherit src;

  # Make the fstack library available when building the examples.
  nativeBuildInputs = [ pkg-config gawk pinnedNixpkgs.dpdk ];
  buildInputs = [
    openssl
    numactl
    pcre
    zlib
    bc
    pinnedNixpkgs.dpdk
    libpcap
    libnl
    libelf
    jansson
    fstack
  ];

  sourceRoot = "${src.name}/example";

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    cp helloworld $out/bin
    runHook postInstall
  '';
}
