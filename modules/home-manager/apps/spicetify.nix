{ inputs, ... }:
{
	flake.modules.homeManager."spicetify" = { osConfig, lib, pkgs, ... }: {
		imports = [ inputs.spicetify-nix.homeManagerModules.default ];

		# switch between the spicetify-patched client and a vanilla spotify client
		programs.spicetify = lib.mkIf osConfig.manifest.enableSpicetify {
			enable = true;
			wayland = true; # native wayland instead of xwayland
		};

		home.packages = lib.mkIf (!osConfig.manifest.enableSpicetify) [
			pkgs.spotify
		];

		# stylix.targets.spicetify (autoEnable) applies the stylix colour scheme.
	};
}