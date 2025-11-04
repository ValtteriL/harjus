{
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  lib,
  cmake,
  ninja,
  openssl
}:

let
  src = fetchFromGitHub {
        owner = "quickfix";
        repo = "quickfix";
        rev =
          "92c85ca63fc260d16e24e0ece419ecdec9ffe868"; # 1.16.0 (no release for this commit)
        hash = "sha256-uw47OvhD25rdJaufdgrefotcjyjn/RxT64WNnm2GHmE=";
      };
in

stdenv.mkDerivation {
  pname = "quickfix";
  version = "1.16.0";

  inherit src;

  patches = [
        # Improved C++17 compatibility
        (fetchpatch {
          url =
            "https://patch-diff.githubusercontent.com/raw/quickfix/quickfix/pull/625.diff";
          hash = "sha256-J4Sw7lPS6gv9gkSn3kAM8RTdoBvpgLeOR4qeXtkjVao=";
        })
        ./patches/00001-fix-build.patch
      ];

  # enable SSL
  cmakeFlags = [ "-DHAVE_SSL=ON" "-DQUICKFIX_EXAMPLES=OFF" "-DQUICKFIX_TESTS=OFF" ];

  enableParallelBuilding = true;
  hardeningDisable = true;

  nativeBuildInputs = [ cmake ninja ];
  buildInputs = [ openssl ];
}