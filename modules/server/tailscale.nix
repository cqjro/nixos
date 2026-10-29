{ ... }:
{
	flake.modules.nixos.tailscale = { config, inputs, lib, pkgs, ... }:
		let
			# tailscale has to track upstream security releases. REDRUM is built
			# from a pinned nixpkgs (modules/hosts/REDRUM/T2-PIN.md) whose
			# tailscale is 1.102.2 *and* whose Go (1.26.5) is too old to build
			# 1.104.4 (go.mod wants >= 1.27.3), so the pin is built from the main
			# `nixpkgs` input's package recipe (Go 1.27.3). That input still ships
			# 1.104.2 as of channel 2026-10-27.
			# TODO-remove: delete `tailscalePinned` and the `package` line once
			# both inputs ship >= 1.104.4, so `pkgs.tailscale` is used again.
			# Bump `version`, `src.hash` and `vendorHash` together; the hashes
			# come from nixpkgs' pkgs/by-name/ta/tailscale/package.nix for that
			# release.
			upstreamPkgs = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
			tailscalePinned = upstreamPkgs.tailscale.overrideAttrs (old: {
				version = "1.104.4";

				src = upstreamPkgs.fetchFromGitHub {
					owner = "tailscale";
					repo = "tailscale";
					tag = "v1.104.4";
					hash = "sha256-sJh3oXFarS1s+flMfm4ZAE+0ZSwp8F3Rib76+qBFVIw=";
				};

				vendorHash = "sha256-RvaouD88naVNOPJBVcqMaAn+ovjXI4g83ShCdRiR5/Q=";
			});
		in {
			services.tailscale = {
				enable = true;
				package = lib.mkDefault tailscalePinned;
			};

			# keep the CLI on the same build the service runs
			environment.systemPackages = [ config.services.tailscale.package ];
		};
}
