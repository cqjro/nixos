{ ... }:
let
	appUser = "miniflux";
	workDir = "/var/lib/miniflux";
in
{
	# Subscribes Miniflux to every feed in `rss-sources.feeds`
	# (modules/system/rss-feeds.json) whenever the list changes, i.e. on the
	# REDRUM switch that deploys the change, and once per boot.
	flake.modules.nixos."miniflux-rss-sync" = { config, pkgs, lib, ... }:
	let
		cfg = config.miniflux-rss-sync;
		# The effective list (JSON file + any per-host merges), frozen in the store.
		feedsJson = pkgs.writeText "rss-feeds.json" (builtins.toJSON config.rss-sources.feeds);
		sync = pkgs.writeShellScript "miniflux-rss-sync" ''
			exec ${pkgs.python3}/bin/python3 -I ${../scripts/rss-sync.py} apply ${lib.optionalString cfg.prune "--prune"}
		'';
	in {
		options.miniflux-rss-sync.prune = lib.mkOption {
			type = lib.types.bool;
			default = false;
			description = ''
				Also delete from Miniflux (with the feed's entries) feeds that were
				dropped from `rss-sources.feeds`. Only feeds the unit itself pushed
				or saw in both places are ever deleted, so feeds added from a phone
				are safe, and a run refuses to prune more than 5 feeds (or anything
				at all when the list is empty). Off by default: removing a line from
				the list then never destroys read/starred state.
			'';
		};

		config.systemd.services.miniflux-rss-sync = {
			description = "Sync rss-sources feeds into Miniflux";
			wantedBy = [ "multi-user.target" ];
			after = [ "miniflux.service" ];
			wants = [ "miniflux.service" ];
			# Re-run on the switch that changes the list (or the prune flag, via the
			# script path); a oneshot with RemainAfterExit is otherwise only started
			# at boot.
			restartTriggers = [ feedsJson ];
			environment = {
				MINIFLUX_URL = "http://${config.services.miniflux.config.LISTEN_ADDR}";
				RSS_SYNC_MASTER = toString feedsJson;
				# Which feeds were already pushed: stops a feed deleted from the
				# Miniflux UI being re-added on every switch.
				RSS_SYNC_SNAPSHOT = "${workDir}/rss-sync-snapshot.json";
				RSS_SYNC_WAIT = "120"; # seconds to wait for Miniflux to answer /healthcheck
				# A Miniflux API key (Settings -> API Keys) created by hand, outside the
				# store (README: "Create app secrets"). Unlike the admin password it does
				# not change when you rotate your login. A missing file is a log line
				# (the "-" on ExecStart below), not a failed switch.
				RSS_SYNC_TOKEN_FILE = "${workDir}/api-token";
			};
			serviceConfig = {
				Type = "oneshot";
				RemainAfterExit = true;
				User = appUser;
				Group = appUser;
				# Subscribing fetches each feed synchronously, so allow time. The
				# leading "-" keeps a failing feed (the unit exits 1 and retries it
				# at the next run) from marking the switch as failed.
				ExecStart = "-${sync}";
				TimeoutStartSec = 600;

				# Only talks to Miniflux on loopback and writes its snapshot.
				IPAddressDeny = "any";
				IPAddressAllow = "localhost";
				RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
				ProtectSystem = "strict";
				ReadWritePaths = [ workDir ];
				ProtectHome = true;
				PrivateTmp = true;
				NoNewPrivileges = true;
			};
		};
	};
}
