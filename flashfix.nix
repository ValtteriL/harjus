{ stdenv, pkg-config, openssl, numactl, pcre, zlib, bc, lib, cmake, ninja
, fstack, dpdk, fstack-mt }:

# get source code from flashfix subdirectory
let
  fs = lib.fileset;
  src = fs.toSource {
    root = ./.;
    fileset = ./flashfix;
  };

in stdenv.mkDerivation {
  pname = "flashfix";
  version = "1.0.0";

  inherit src;

  nativeBuildInputs = [ pkg-config cmake ninja ];
  buildInputs = [ openssl numactl pcre zlib bc fstack dpdk fstack-mt ];

  configurePhase = ''
    runHook preConfigure
    cmake flashfix -G Ninja
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    ninja
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cmake --install . --prefix $out
    runHook postInstall
  '';
}
