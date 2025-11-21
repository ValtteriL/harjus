{ stdenv, pname, version, harjusbuild}:

let
  src = harjusbuild.src;

in stdenv.mkDerivation {
  inherit pname version src;
  buildInputs = [ harjusbuild ];
  installPhase = ''
        mkdir -p $out/bin
        ln -s ${harjusbuild}/bin/harjus $out/bin/harjus
        echo "Harjus version ${version} installed successfully!" > $out/version.txt
      '';
}
