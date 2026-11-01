{ lib, ... }:
{
	flake.modules.nixos.rss-sources = { pkgs, config, ... }:
	let
		cfg = config.rss-sources;
		esc = lib.escapeXML;

		# One <outline> per feed. Feeds with a `category` are nested under an
		# outline of that name (Miniflux, FreshRSS & co. turn those into
		# categories/folders); the rest stay at the top level.
		feedOutline = f: ''<outline type="rss" text="${esc f.title}" title="${esc f.title}" xmlUrl="${esc f.url}"/>'';
		categories = lib.unique (lib.catAttrs "category" (lib.filter (f: f.category != null) cfg.feeds));
		categoryOutline = c:
			[ ''<outline text="${esc c}" title="${esc c}">'' ]
			++ map (f: "  " + feedOutline f) (lib.filter (f: f.category == c) cfg.feeds)
			++ [ "</outline>" ];
		# Built from a line list: the XML declaration must be the very first bytes.
		opmlText = lib.concatStringsSep "\n" (
			[ ''<?xml version="1.0" encoding="UTF-8"?>'' ''<opml version="2.0">'' "<head><title>rss-sources</title></head>" "<body>" ]
			++ lib.concatMap categoryOutline categories
			++ map feedOutline (lib.filter (f: f.category == null) cfg.feeds)
			++ [ "</body>" "</opml>" ""]
		);
	in {
		options.rss-sources = {
			feeds = lib.mkOption {
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
						category = lib.mkOption {
							type = lib.types.nullOr lib.types.str;
							default = null;
							description = ''
								Single category/folder for apps that have one (Miniflux, the
								generated OPML). `null` leaves the feed in the app's default.
							'';
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
				# The list lives in a data file so `rss-sync` (modules/scripts/rss-sync.py)
				# can add/remove entries without editing Nix source.
				default = builtins.fromJSON (builtins.readFile ./rss-feeds.json);
				description = ''
					Standard RSS/Atom feeds shared by every rss consumer on the host: the
					glance rss widget reads them directly via `config.rss-sources.feeds`,
					and user-level modules consume the same list through
					`osConfig.rss-sources.feeds`. The default comes from `rss-feeds.json`;
					extend per host (or globally) by merging into this option.
				'';
			};

			opml = lib.mkOption {
				type = lib.types.path;
				readOnly = true;
				default = pkgs.writeText "rss-sources.opml" opmlText;
				description = ''
					The feed list as an OPML file, for bulk-importing into any reader.
					Also linked at `/etc/rss-sources.opml`.
				'';
			};
		};

		config.environment.etc."rss-sources.opml".source = cfg.opml;
	};
}
