{ lib, ... }:
{
	flake.modules.nixos.rss-sources = {
		options.rss-sources.feeds = lib.mkOption {
			type = lib.types.listOf (lib.types.submodule {
				options = {
					url = lib.mkOption {
						type = lib.types.str;
						description = "RSS/Atom feed URL.";
					};
					title = lib.mkOption {
						type = lib.types.str;
						description = "Human-readable feed name (shown by the glance rss widget and nom).";
					};
					tags = lib.mkOption {
						type = lib.types.listOf lib.types.str;
						default = [];
						description = "Free-form tags for categorising/filtering feeds (consumed by apps that support them, e.g. nom).";
					};
					limit = lib.mkOption {
						type = lib.types.nullOr lib.types.int;
						default = null;
						description = "Optional per-feed item limit (honoured by the glance rss widget).";
					};
				};
			});
			default = [
				{ url = "https://selfh.st/rss/"; title = "selfh.st"; tags = [ "selfhosted" ]; limit = 4; }
				{ url = "https://ciechanow.ski/atom.xml"; title = "Ciechanow.ski"; tags = [ "dev" "engineering" ]; }
				{ url = "https://www.joshwcomeau.com/rss.xml"; title = "Josh W. Comeau"; tags = [ "dev" "frontend" ]; }
				{ url = "https://samwho.dev/rss.xml"; title = "Sam Rose"; tags = [ "dev" ]; }
				{ url = "https://ishadeed.com/feed.xml"; title = "Ahmad Shadeed"; tags = [ "dev" "frontend" "css" ]; }
			];
			description = ''
				Standard RSS/Atom feeds shared by every rss consumer on the host: the
				glance rss widget reads them directly via `config.rss-sources.feeds`,
				and user-level modules consume the same list through
				`osConfig.rss-sources.feeds`. Extend per host (or globally) by
				merging into this option.
			'';
		};
	};
}