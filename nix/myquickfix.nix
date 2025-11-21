{ stdenv, fetchFromGitHub, fetchpatch, enableParallelBuilding, hardeningDisable
, cmake, ninja, openssl }:

let
  pname = "quickfix";
  version = "1.16.0";

  src = fetchFromGitHub {
    owner = "quickfix";
    repo = "quickfix";
    rev =
      "92c85ca63fc260d16e24e0ece419ecdec9ffe868"; # 1.16.0 (no release for this commit)
    hash = "sha256-uw47OvhD25rdJaufdgrefotcjyjn/RxT64WNnm2GHmE=";
  };

  patches = [
    # Improved C++17 compatibility
    (fetchpatch {
      url =
        "https://patch-diff.githubusercontent.com/raw/quickfix/quickfix/pull/625.diff";
      hash = "sha256-J4Sw7lPS6gv9gkSn3kAM8RTdoBvpgLeOR4qeXtkjVao=";
    })
    ./patch/00001-fix-build.patch
  ];

in stdenv.mkDerivation {
  inherit pname version src patches enableParallelBuilding hardeningDisable;

  # enable SSL
  cmakeFlags =
    [ "-DHAVE_SSL=ON" "-DQUICKFIX_EXAMPLES=OFF" "-DQUICKFIX_TESTS=OFF" ];

  nativeBuildInputs = [ cmake ninja ];
  buildInputs = [ openssl ];
}
