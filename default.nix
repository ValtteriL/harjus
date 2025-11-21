# default.nix
let
  nixpkgs = fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/3f0a8ac25fb674611b98089ca3a5dd6480175751.tar.gz";
    sha256 = "sha256:10i7fllqjzq171afzhdf2d9r1pk9irvmq5n55h92rc47vlaabvr4";
  };
  pkgs = import nixpkgs {
    config = { allowUnfree = true; };
    overlays = [ ];
  };

  pname = "harjus";
  version = "latest";

  gccFlags =
    "-O3 -march=icelake-server -mtune=icelake-server -pipe -fsemantic-interposition";

  enableParallelBuilding = true;

  # disable performance affecting hardenings
  hardeningDisable =
    [ "fortify" "stackprotector" "pic" "pie" "relro" "bindnow" ];

in rec {
  myQuickfix = pkgs.callPackage ./myquickfix.nix { hardeningDisable = hardeningDisable; enableParallelBuilding = enableParallelBuilding; };

  myQuickfixOptimized = myQuickfix.overrideAttrs (finalAttrs: {
    # override compile flags to optimize for performance
    NIX_CFLAGS_COMPILE = gccFlags;
  });

  run-clang-tidy = pkgs.callPackage ./flashfix/run-clang-tidy.nix { };

  devEnv = pkgs.callPackage ./devEnv.nix { myQuickfix = myQuickfix; runClangTidy = run-clang-tidy; };

  harjusbuild = pkgs.callPackage ./harjusbuild.nix {
    hardeningDisable = hardeningDisable;
    enableParallelBuilding = enableParallelBuilding;
    gccFlags = gccFlags;
    myQuickfixOptimized = myQuickfixOptimized;
  };

  harjus = pkgs.callPackage ./harjus.nix {
    harjusbuild = harjusbuild;
    pname = pname;
    version = version;
  };
}
