{ stdenv, fetchFromGitHub, fstack, pkg-config, gawk, openssl, numactl, pcre
, zlib, bc, lib, libpcap, libnl, libelf, jansson }:

let
  src = fetchFromGitHub {
    owner = "F-Stack";
    repo = "f-stack";
    rev = "1.24";
    sha256 = "sha256-zsIOQ03q/33VPME12CnMOo79xZRIpETrcZwuEMwyXQ8=";
  };

  # commit where dpdk is at version 22.11.1 (close to the f-stack 1.24 supported 22.11.6)
  pinnedNixpkgs = import (fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/203e5461b25add434893bee7ba8bdfeeffffebf0.tar.gz";
    sha256 = "sha256:1b5gcaxl461pbiawcyqh5zh6smlp25sbm00d9cla9il4rd928jyp";
  }) { };

  pkgVersion = "1.24";

in stdenv.mkDerivation {
  pname = "fstack-mt";
  version = "1.24";

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
