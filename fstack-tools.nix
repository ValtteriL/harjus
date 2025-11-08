{
  stdenv,
  fetchFromGitHub,
  fstack,
  pkg-config,
  gawk,
  openssl,
  numactl,
  pcre,
  zlib,
  bc,
  lib,
  libpcap,
  libnl,
  libelf,
  jansson
}:

let
  src = fetchFromGitHub {
    owner = "F-Stack";
    repo = "f-stack";
    rev = "1.24";
    sha256 = "sha256-zsIOQ03q/33VPME12CnMOo79xZRIpETrcZwuEMwyXQ8=";
  };

  # commit where dpdk is at version 22.11.1 (close to the f-stack 1.24 supported 22.11.6)
  pinnedNixpkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/203e5461b25add434893bee7ba8bdfeeffffebf0.tar.gz";
    sha256 = "sha256:1b5gcaxl461pbiawcyqh5zh6smlp25sbm00d9cla9il4rd928jyp";
  }) {};

in

stdenv.mkDerivation {
  pname = "fstack-tools";
  version = "1.24";

  inherit src;

  # Make the fstack library available when building the examples.
  nativeBuildInputs = [ pkg-config gawk pinnedNixpkgs.dpdk ];
  buildInputs = [ openssl numactl pcre zlib bc pinnedNixpkgs.dpdk libpcap libnl libelf jansson fstack ];

  sourceRoot = "${src.name}/tools";

  # Disable treating warnings as errors by default and patch Makefiles at build time
  makeFlags = [ "WERROR=" ];

  patchPhase = ''
    runHook prePatch

    # Replace hard-coded -Werror in Makefiles and .mk files with a configurable
    # $(WERROR) variable and add a default WERROR if missing. This keeps the
    # original behaviour unless the builder sets WERROR= (we default to empty
    # via makeFlags above).

    for f in $(find . -type f \( -name 'Makefile' -o -name '*.mk' \) -print); do
      if grep -q -- '-Werror' "$f" 2>/dev/null; then
        # add a default WERROR if not present
        if ! grep -q '^WERROR ?=' "$f" 2>/dev/null; then
          sed -i '1iWERROR ?= -Werror' "$f"
        fi
        # replace literal occurrences with $(WERROR)
        sed -i 's/-Werror/$(WERROR)/g' "$f"
      fi
    done

    runHook postPatch
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"

    # Install all tools binaries
    cp sbin/arp "$out/bin/ff_arp"
    cp sbin/ndp "$out/bin/ff_ndp"
    cp sbin/ifconfig "$out/bin/ff_ifconfig"
    cp sbin/ipfw "$out/bin/ff_ipfw"
    cp sbin/netstat "$out/bin/ff_netstat"
    cp sbin/ngctl "$out/bin/ff_ngctl"
    cp sbin/route "$out/bin/ff_route"
    cp sbin/sysctl "$out/bin/ff_sysctl"
    cp sbin/top "$out/bin/ff_top"
    cp sbin/traffic "$out/bin/ff_traffic"
    cp sbin/knictl "$out/bin/ff_knictl"

    runHook postInstall
  '';

}
