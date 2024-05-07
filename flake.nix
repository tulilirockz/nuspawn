{
  description = "Nspawn wrapper for fetching tarballs from nspawnhub";
  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*.tar.gz";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
  };
  outputs = { self, flake-schemas, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in {
      packages = forEachSupportedSystem ({ pkgs }: rec {
        default = nuspawn;
        nuspawn = pkgs.stdenvNoCC.mkDerivation rec {
          pname = "nuspawn";
          name = pname;
          src = pkgs.lib.cleanSource ./.;

          buildInputs = with pkgs; [ systemd ];

          buildCommand = ''
            mkdir -p $out/bin $out/lib
            cp $src/src/${pname} $out/bin
            substituteInPlace $out/bin/${pname} --replace 'lib/' "$out/lib/"
            cp -r $src/src/lib/* $out/lib
          '';
        };
      });

      schemas = flake-schemas.schemas;
      formatter = forEachSupportedSystem ({ pkgs }: pkgs.nixfmt-rfc-style);
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {        
          packages = with pkgs; [
            nushell
          ];
        };
      });
    };
}
