{
  description = "Nspawn wrapper for fetching tarballs from nspawnhub";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
  outputs = { self, nixpkgs }:
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

          buildInputs = with pkgs; [ systemd gnutar coreutils nushell ];

          buildCommand = ''
            mkdir -p $out/bin $out/lib
            cp $src/src/${pname} $out/bin
            substituteInPlace $out/bin/${pname} --replace-warn './lib' "$out/lib/"
            patchShebangs $out/bin/${pname}
            cp -r $src/src/lib/* $out/lib
          '';
        };
      });
      formatter = forEachSupportedSystem ({ pkgs }: pkgs.nixfmt-rfc-style);
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {        
          packages = with pkgs; [
            nushell
            gitFull
          ];
        };
      });
    };
}
