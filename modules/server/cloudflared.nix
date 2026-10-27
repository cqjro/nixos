{ inputs, ... }:
{
	# cloudflared cuts releases much faster than the nixpkgs pin REDRUM builds
	# from (see modules/hosts/REDRUM/T2-PIN.md), so both the tunnel daemon and
	# the CLI are taken from the unpinned `nixpkgs` input.
	# TODO-remove: drop the `package` override and go back to `pkgs.cloudflared`
	# when the T2 pin is lifted.
	flake.modules.nixos.cloudflared = { config, lib, pkgs, ... }: {
		services.cloudflared = {
			enable = true;
			package = lib.mkDefault
				inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.cloudflared;
		};

		# keep the CLI on the same build the service runs
		environment.systemPackages = [ config.services.cloudflared.package ];
	};
}
