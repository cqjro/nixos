{ ... }:
{
	flake.modules.homeManager."rss-sync" = { pkgs, ... }: {
		# Two-way sync between modules/system/rss-feeds.json and Miniflux
		# (modules/scripts/rss-sync.py). The API token is created by hand in
		# Miniflux (Settings -> API Keys) and stored in ~/.config/rss-sync/api-token.
		home.packages = [
			(pkgs.writeShellScriptBin "rss-sync" ''
				exec ${pkgs.python3}/bin/python3 -I ${../../scripts/rss-sync.py} "$@"
			'')
		];
	};
}
