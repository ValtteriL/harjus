# default.nix
let
  nixpkgs = fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/c2448301fb856e351aab33e64c33a3fc8bcf637d.tar.gz";
    sha256 = "sha256:1rcvx4x6kc652pan6jggpqfvrzydhfi9k3kpjkj55mc38dwl690y";
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

  # commit where dpdk is at version 23.11 (close to the f-stack 1.25 supported 23.11.5)
  pinnedNixpkgs = import (fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/571c71e6f73af34a229414f51585738894211408.tar.gz";
    sha256 = "sha256:0fgp5sqfmh5zgx75rs5101ywkz0fkjff67abms0kc8hyaxmlc7js";
  }) { };
in rec {
  myQuickfix = pkgs.callPackage ./nix/myquickfix.nix {
    hardeningDisable = hardeningDisable;
    enableParallelBuilding = enableParallelBuilding;
  };

  myQuickfixOptimized = myQuickfix.overrideAttrs (finalAttrs: {
    # override compile flags to optimize for performance
    NIX_CFLAGS_COMPILE = gccFlags;
  });

  fstack = pkgs.callPackage ./nix/fstack.nix { dpdk = pinnedNixpkgs.dpdk; };
  fstack-examples = pkgs.callPackage ./nix/fstack-examples.nix {
    fstack = fstack;
    dpdk = pinnedNixpkgs.dpdk;
  };

  fstack-mt = pkgs.callPackage ./nix/fstack-mt.nix {
    fstack = fstack;
    dpdk = pinnedNixpkgs.dpdk;
  };

  fstack-tools = pkgs.callPackage ./nix/fstack-tools.nix {
    fstack = fstack;
    dpdk = pinnedNixpkgs.dpdk;
  };

  flashfix = pkgs.callPackage ./nix/flashfix.nix {
    fstack = fstack;
    fstack-mt = fstack-mt;
    dpdk = pinnedNixpkgs.dpdk;
  };

  run-clang-tidy = pkgs.callPackage ./nix/run-clang-tidy.nix { };
  git-clang-format = pkgs.callPackage ./nix/git-clang-format.nix { };

  devEnv = pkgs.callPackage ./nix/devEnv.nix {
    myQuickfix = myQuickfix;
    fstack = fstack;
    fstack-examples = fstack-examples;
    fstack-mt = fstack-mt;
    fstack-tools = fstack-tools;
    run-clang-tidy = run-clang-tidy;
    git-clang-format = git-clang-format;
    flashfix = flashfix;
  };

  harjusbuild = pkgs.callPackage ./nix/harjusbuild.nix {
    hardeningDisable = hardeningDisable;
    enableParallelBuilding = enableParallelBuilding;
    gccFlags = gccFlags;
    myQuickfixOptimized = myQuickfixOptimized;
  };

  harjus = pkgs.callPackage ./nix/harjus.nix {
    harjusbuild = harjusbuild;
    pname = pname;
    version = version;
  };
}
