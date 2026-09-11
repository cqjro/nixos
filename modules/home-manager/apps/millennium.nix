{ inputs, ... }:
{
	flake.modules.homeManager."millennium" = { config, lib, pkgs, ... }: {
		# re1n0/nixos-millennium's home-manager module (stylix submodule excluded:
		# it expects base10-base16 colours our scheme does not define)
		imports = [ "${inputs.nixos-millennium}/home-modules/steam.nix" ];

		programs.steam = {
			theme = pkgs.millenniumThemes.space;

			# map our base16 palette onto the Space theme's --st-* variables
			millenniumConfig.themes.themeColors."space-theme-steam" = let
				hexToRGB = hex: let
					r = lib.fromHexString (builtins.substring 0 2 hex);
					g = lib.fromHexString (builtins.substring 2 2 hex);
					b = lib.fromHexString (builtins.substring 4 2 hex);
				in "${toString r}, ${toString g}, ${toString b}";
				c = config.lib.stylix.colors;
			in {
				"--st-background" = hexToRGB c.base00;

				"--st-accent-1" = hexToRGB c.base0D;
				"--st-accent-2" = hexToRGB c.base0E;

				"--st-color-1" = hexToRGB c.base05;
				"--st-color-2" = hexToRGB c.base00;
				"--st-color-3" = hexToRGB c.base01;
				"--st-color-4" = hexToRGB c.base02;
				"--st-color-5" = hexToRGB c.base03;

				"--st-blue" = hexToRGB c.base0D;
				"--st-blue-hover" = hexToRGB c.base0C;

				"--st-green" = hexToRGB c.base0B;
				"--st-green-hover" = hexToRGB c.base0C;

				"--st-red" = hexToRGB c.base08;
				"--st-red-hover" = hexToRGB c.base09;

				"--st-yellow" = hexToRGB c.base0A;
				"--st-yellow-hover" = hexToRGB c.base09;
			};
		};
	};
}