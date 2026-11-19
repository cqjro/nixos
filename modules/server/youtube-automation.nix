{ inputs, ... }:
let
	system = "x86_64-linux";
	pkgs = inputs.nixpkgs.legacyPackages.${system};

	# Python libraries shared by the sync service, the devShell and the auth helper.
	pyDeps = ps: with ps; [
		google-api-python-client
		google-auth-httplib2
		google-auth-oauthlib
		requests
	];

	# Everything the sync user owns lives here: config.json and token.json (hand-placed,
	# never in git) plus the lock file. The scripts are Nix-managed (store paths) and
	# only symlinked in. Procedure to mint a token: docs/secrets.md 4.8.
	stateDir = "/var/lib/youtube-sync";
in
{
	flake.devShells.${system}.youtube-sync = pkgs.mkShell {
		packages = [ (pkgs.python3.withPackages pyDeps) ];
	};

	# `nix run .#youtube-sync-auth` on a machine with a browser (THEOCIDE), from a scratch
	# directory holding client_secret.json: writes token.json there. See modules/scripts/setup_auth.py.
	flake.packages.${system}.youtube-sync-auth = pkgs.writeShellApplication {
		name = "youtube-sync-auth";
		runtimeInputs = [ (pkgs.python3.withPackages pyDeps) ];
		text = ''exec python3 ${../scripts/setup_auth.py} "$@"'';
	};

	flake.modules.nixos.youtube = { pkgs, ... }:
	let
		pythonEnv = pkgs.python3.withPackages pyDeps;
	in
	{
		users.users.youtube-sync = {
			isSystemUser = true;
			group = "youtube-sync";
			home = stateDir;
		};
		users.groups.youtube-sync = {};

		systemd.tmpfiles.rules = [
			"d ${stateDir} 0700 youtube-sync youtube-sync -"
			# Handy for `sudo -u youtube-sync python3 sync_playlist.py --dry-run --verbose`;
			# the service itself runs the store path directly.
			"L+ ${stateDir}/sync_playlist.py - - - - ${../scripts/sync_playlist.py}"
		];

		systemd.services.youtube-playlist-sync = {
			description = "Sync YouTube subscriptions uploads from last 24 hours into playlist";
			serviceConfig = {
				Type = "oneshot";
				User = "youtube-sync";
				Group = "youtube-sync";
				WorkingDirectory = stateDir;
				# Script is Nix-managed; only config.json / token.json live in stateDir
				# (token_file defaults to "token.json", relative to WorkingDirectory).
				ExecStart = "${pythonEnv}/bin/python3 ${../scripts/sync_playlist.py} --config ${stateDir}/config.json";

				# Hardening
				ProtectSystem = "strict";
				ProtectHome = true;
				ReadWritePaths = [ stateDir ];
				NoNewPrivileges = true;
				PrivateTmp = true;
			};
		};

		systemd.timers.youtube-playlist-sync = {
			description = "Run youtube-playlist-sync periodically";
			wantedBy = [ "timers.target" ];
			timerConfig = {
				# Hourly: at 15 min the Data API quota (10,000 units/day) ran out, since
				# channels whose RSS feed fails fall back to a 1-unit API call each.
				OnBootSec = "5m";
				OnUnitActiveSec = "1h";
				Persistent = true;
			};
		};
	};
}
