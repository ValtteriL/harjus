{ stdenv, fetchFromGitHub, pkg-config, gawk, openssl, numactl, pcre, zlib, bc
, lib }:

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
  pname = "fstack";
  version = pkgVersion;

  inherit src;

  sourceRoot = "${src.name}/lib";

  nativeBuildInputs = [ pkg-config gawk ];
  buildInputs = [ openssl numactl pcre zlib bc pinnedNixpkgs.dpdk ];

  # Install into the Nix store: create directories and call make install with
  # PREFIX variables so the Makefile writes into $out instead of /usr/local.
  installPhase = ''
        runHook preInstall
        mkdir -p "$out/lib" "$out/include" "$out/bin" "$out/etc"
        make install PREFIX_LIB=$out/lib PREFIX_INCLUDE=$out/include \
          PREFIX_BIN=$out/bin F-STACK_CONF=$out/etc/f-stack.conf
        # Install a pkg-config file so downstream derivations using pkg-config
        # can discover the library under the name "libfstack".
        mkdir -p "$out/lib/pkgconfig"
      cat > "$out/lib/pkgconfig/libfstack.pc" <<EOF
    prefix=$out
    exec_prefix=$''${prefix}
    libdir=$''${exec_prefix}/lib
    includedir=$''${prefix}/include

    Name: libfstack
    Description: F-Stack user-space network stack
    Version: ${pkgVersion}
    Libs: -L$''${libdir} -lfstack
    Cflags: -I$''${includedir}
    EOF
        runHook postInstall
  '';
}
