{ ... }:
{
	# cloudflared has to track upstream for security fixes, but REDRUM is built
	# from a pinned nixpkgs (modules/hosts/REDRUM/T2-PIN.md): that rev ships
	# 2026.7.3, and the locked `nixpkgs` input only reaches 2026.10.1.
	# TODO-remove: this pins Cloudflare's own (static, signed) release binary.
	# Once `nixpkgs` is bumped — master already has 2026.10.3 — delete
	# `cloudflaredPinned` and let `services.cloudflared.package` fall back to
	# `pkgs.cloudflared`. Bump `version` + `hash` together in the meantime
	# (hash from: nix-prefetch-url <the release URL>).
	flake.modules.nixos.cloudflared = { config, lib, pkgs, ... }:
		let
			cloudflaredPinned = pkgs.stdenvNoCC.mkDerivation (final: {
				pname = "cloudflared";
				version = "2026.10.2";

				src = pkgs.fetchurl {
					url = "https://github.com/cloudflare/cloudflared/releases/download/${final.version}/cloudflared-linux-amd64";
					hash = "sha256-NfvdK+s3hDbH2jd9c1jOqOM/nJSmcF0dgDa/mw1tgAU=";
				};

				dontUnpack = true;
				installPhase = ''
					install -Dm755 $src $out/bin/cloudflared
				'';

				meta = {
					description = "Cloudflare Tunnel client (release binary pin)";
					homepage = "https://github.com/cloudflare/cloudflared";
					mainProgram = "cloudflared";
					platforms = [ "x86_64-linux" ];
				};
			});
		in {
			services.cloudflared = {
				enable = true;
				package = lib.mkDefault cloudflaredPinned;
			};

			# keep the CLI on the same build the service runs
			environment.systemPackages = [ config.services.cloudflared.package ];
		};
}
