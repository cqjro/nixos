{
  description = "OpenBubbles (openbubbles-app) flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
				lib = pkgs.lib;
      in {
        packages.openbubbles-app = pkgs.stdenv.mkDerivation {
          pname = "openbubbles-app";
          version = "2025-08-03";

          src = pkgs.fetchFromGitHub {
            owner = "OpenBubbles";
            repo = "openbubbles-app";
            rev = "0b72b91a5c69dc3355374709767aa9e8c6b922f7";
            # you can pin to a known commit/branch
            # temporarily use lib.fakeSha256 and then fill in via build
            # sha256 = "0000000000000000000000000000000000000000000000000000";
						sha256 = "1a2wg8qmrqwkcnz6p9gr01p1vz0fwl34gymyqqwjxrjw8gd106yg";
          };

          nativeBuildInputs = with pkgs; [ flutter dart yarn ];

          buildPhase = "yarn && yarn build";

          installPhase = ''
            mkdir -p $out/bin
            cp -r build/linux-unpacked/* $out/bin/
          '';

          meta = with lib; {
            description = "Client for OpenBubbles ecosystem (iMessage/FaceTime on non‑Apple platforms)";
            homepage = "https://github.com/OpenBubbles/openbubbles-app";
            license = licenses.asl20;
            platforms = platforms.unix;
          };
        };
      });
}


