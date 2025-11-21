{ stdenv, fetchurl, python3, lib }:

let
  src = fetchurl {
    url =
      "https://raw.githubusercontent.com/llvm/llvm-project/refs/tags/llvmorg-20.1.7/clang-tools-extra/clang-tidy/tool/run-clang-tidy.py";
    hash = "sha256-Kyus9SXaulqxg/mP29DyHfi7Qh4V2TiyJFGAlEGG/HM=";
  };

in stdenv.mkDerivation {
  pname = "runClangTidy";
  version = "20.1.17";

  inherit src;

  buildInputs = [ python3 ];

  dontUnpack = true;
  installPhase = "install -D -m 0755 $src $out/bin/run-clang-tidy";
}

