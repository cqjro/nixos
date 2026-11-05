{ inputs, ... }:
{
	flake.modules.homeManager."opencode" = { pkgs, ... }: {
		programs.opencode = {
			enable = true;
			# TODO-remove: previous nixpkgs, because pkgs.opencode's node_modules
			# fixed-output hash is stale on the main nixpkgs (registry row 10). Once
			# `nix build nixpkgs#opencode` works, drop `package` and the input.
			package = inputs.nixpkgs-opencode.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode;
		};
	};
}
