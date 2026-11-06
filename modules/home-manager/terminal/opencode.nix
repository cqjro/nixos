{ inputs, ... }:
{
	flake.modules.homeManager."opencode" = { pkgs, lib, ... }: {
		programs.opencode = {
			enable = true;
			# TODO-remove: registry row 12. OpenCode 2 ignores tui.json, and Stylix still writes its theme name to
			# programs.opencode.tui, which warns. Empty it (Stylix still generates the
			# theme itself, programs.opencode.themes.stylix) and select the theme
			# through cli.json instead.
			tui = lib.mkForce { };
			cli.theme = "stylix";
			# TODO-remove: previous nixpkgs, because pkgs.opencode's node_modules
			# fixed-output hash is stale on the main nixpkgs (registry row 10). Once
			# `nix build nixpkgs#opencode` works, drop `package` and the input.
			package = inputs.nixpkgs-opencode.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode;
		};
	};
}
