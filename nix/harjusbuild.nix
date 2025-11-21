{ stdenv, lib, fetchpatch, enableParallelBuilding, hardeningDisable, pkgs}:

let
  pname = "harjusbuild";
  version = "rolling";

  src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [ ./src ./CMakeLists.txt ./include ];
      };

in stdenv.mkDerivation {
  inherit pname version src enableParallelBuilding hardeningDisable;

  cmakeFlags = [ "-DHARJUS_TESTS=OFF" ];

  buildInputs = with pkgs;[
        gtest
        boost
        openssl
        libcpr
        pkg-config
        libsodium
        gmp
        myQuickfixOptimized
      ];
      nativeBuildInputs = with pkgs; [ cmake ninja pkg-config ];

      NIX_CFLAGS_COMPILE = gccFlags;
}
