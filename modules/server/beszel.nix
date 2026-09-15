{ ... }:
{
	flake.modules.nixos.beszel = { pkgs, lib, ... }:
	let
		workDir = "/var/lib/beszel";
	in
	{
		# Dedicated users, mirroring the linkwarden/actual-budget modules:

		# The nixpkgs module uses DynamicUser=true for the hub, but we pin it to
		# a stable dedicated user so the admin (and `sudo -u`) can manage the
		# data directory and files under /var/lib/beszel-hub.
		users.users.beszel-hub = {
			isSystemUser = true;
			group = "beszel-hub";
			home = "/var/lib/beszel-hub";
			createHome = true;
		};
		users.groups.beszel-hub = {};

		# The agent already gets a dedicated user from the nixpkgs module
		# (skipped when SKIP_SYSTEMD=true); make it explicit with a home dir.
		users.users.beszel-agent = {
			isSystemUser = true;
			group = "beszel-agent";
			home = "/var/lib/beszel-agent";
			createHome = true;
		};
		users.groups.beszel-agent = {};

		services.beszel.hub = {
			enable = true;
			host = "127.0.0.1"; # only reachable via cloudflared tunnel
			port = 8090; # default
			environment = {
				APP_URL = "https://status.cqjro.ca";
			};
		};

		# Pin the hub to its dedicated user instead of a dynamic user.
		systemd.services.beszel-hub.serviceConfig = {
			DynamicUser = lib.mkForce false;
			User = "beszel-hub";
			Group = "beszel-hub";
		};

		# Agent monitoring REDRUM itself. It connects outbound to the hub via
		# HUB_URL, so its public KEY (and optional TOKEN) live outside the nix
		# store in `${workDir}/agent.env` — see the file permission steps below.
		services.beszel.agent = {
			enable = true;
			environment = {
				HUB_URL = "http://127.0.0.1:8090";
				LISTEN = "127.0.0.1:45876";
			};
			environmentFile = "${workDir}/agent.env";
		};

		services.cloudflared = {
			tunnels."e42f1dc5-6c7a-4a20-9723-cbc55436d577" = {
				credentialsFile = "/var/lib/cloudflared/beszel.json";
				default = "http_status:404";
				ingress = {
					"status.cqjro.ca" = "http://localhost:8090";
				};
			};
		};
	};
}
