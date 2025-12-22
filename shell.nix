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

  nativeBuildInputs = with pkgs; [
      # for working with nix
      nixpkgs-fmt
      nixfmt-classic

      # development
      just
      cmake
      llvmPackages_21.clang-tools
      uv

      # deployment
      terraform
      awscli2
  ];
in pkgs.mkShell {
  inherit nativeBuildInputs;
}
