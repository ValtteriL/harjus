{ stdenv, fetchurl, python3, lib }:

let
  src = fetchurl {
    url =
      "https://raw.githubusercontent.com/llvm/llvm-project/refs/tags/llvmorg-21.1.5/clang/tools/clang-format/git-clang-format";
    hash = "sha256-4ZBDjZ45bWKeq9aoPIVZaegfS90qIRUyxAzeq5FFpCE=";
  };

in stdenv.mkDerivation {
  pname = "gitClangFormat";
  version = "21.1.5";

  inherit src;

  buildInputs = [ python3 ];

  dontUnpack = true;
  installPhase = "install -D -m 0755 $src $out/bin/git-clang-format";
}

