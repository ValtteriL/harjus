{ stdenv, fetchFromGitHub, pkg-config, gawk, openssl, numactl, pcre, zlib, bc
, lib, dpdk }:

let
  src = fetchFromGitHub {
    owner = "F-Stack";
    repo = "f-stack";
    rev = "v1.25";
    sha256 = "sha256-k7GEg3oAr/1qQcXBa6ABIGv4cQ9/i8IRqoGR7AGVLbM=";
  };

  pkgVersion = "1.25";

in stdenv.mkDerivation {
  pname = "fstack";
  version = pkgVersion;

  inherit src;

  sourceRoot = "${src.name}/lib";

  nativeBuildInputs = [ pkg-config gawk ];
  buildInputs = [ openssl numactl pcre zlib bc dpdk ];

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
