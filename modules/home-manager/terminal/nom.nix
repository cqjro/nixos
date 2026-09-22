{ lib, ... }:
{
	flake.modules.homeManager."nom" = { osConfig, ... }: {
		programs.nom = {
			enable = true;
			# Seed nom with the shared feed list so every rss app reads the same
			# sources (defined in modules/system/rss-sources.nix).
			settings.feeds = map (f: { url = f.url; name = f.title; }
				// lib.optionalAttrs (f.tags != []) { inherit (f) tags; })
				osConfig.rss-sources.feeds;
		};
	};
}