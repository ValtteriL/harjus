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

  pkgVersion = "1.25";

in stdenv.mkDerivation {
  pname = "fstack-mt";
  version = pkgVersion;

  inherit src;

  # Make the fstack library available when building the examples.
  nativeBuildInputs = [ pkg-config gawk pinnedNixpkgs.dpdk ];
  propagatedBuildInputs = [
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

  sourceRoot = "${src.name}/adapter/micro_thread";

  # disable performance affecting hardenings
  hardeningDisable =
    [ "fortify" "stackprotector" "pic" "pie" "relro" "bindnow" ];

  buildPhase = ''
    runHook preBuild
    make echo
    runHook postBuild
  '';

  installPhase = ''
        runHook preInstall
        mkdir -p "$out/bin" "$out/lib" "$out/include"
        cp echo "$out/bin/fstack-mt-echo"
        cp libmt.a "$out/lib/"
        cp -r *.h "$out/include/"


        # add a pkg-config file for libmt
        mkdir -p "$out/lib/pkgconfig"
        cat > "$out/lib/pkgconfig/libmt.pc" <<EOF
    prefix=$out
    exec_prefix=$''${prefix}
    libdir=$''${exec_prefix}/lib
    includedir=$''${prefix}/include

    Name: libmt
    Description: F-Stack multi-threading adapter library
    Version: ${pkgVersion}
    Libs: -L$''${libdir} -lmt
    Libs.private: -L$''${libdir} -lfstack
    Cflags: -I$''${includedir}
    EOF

        runHook postInstall
  '';
}
