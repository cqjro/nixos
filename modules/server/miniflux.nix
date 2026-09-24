{ ... }:
let
	appUser = "miniflux";
	workDir = "/var/lib/miniflux";
in
{
	flake.modules.nixos.miniflux = { pkgs, lib, ... }: {
		# Dedicated user, mirroring the linkwarden/actual-budget modules. The
		# nixpkgs module uses DynamicUser=true by default; we pin it to a stable
		# user so the admin (and `sudo -u`) can manage /var/lib/miniflux and the
		# admin credentials file (see the unit override below).
		users.users.${appUser} = {
			isSystemUser = true;
			group = appUser;
			home = workDir;
			createHome = true;
		};
		users.groups.${appUser} = {};

		services.miniflux = {
			enable = true;
			# ADMIN_USERNAME / ADMIN_PASSWORD live outside the nix store in
			# environment-file format (KEY=VALUE lines) — see the README steps
			# for creating /var/lib/miniflux/admin.env.
			adminCredentialsFile = "${workDir}/admin.env";
			createDatabaseLocally = true; # adds a miniflux db to the local postgres (shared with linkwarden)
			config = {
				LISTEN_ADDR = "127.0.0.1:8084"; # only reachable via cloudflared tunnel
				BASE_URL = "https://feed.cqjro.ca"; # public URL used for links/notifications
				# RUN_MIGRATIONS default (1) is fine; admin is created from adminCredentialsFile.
			};
		};

		# Pin miniflux to its dedicated user instead of a dynamic user.
		systemd.services.miniflux.serviceConfig = {
			DynamicUser = lib.mkForce false;
			User = appUser;
			Group = appUser;
		};

		services.cloudflared = {
			tunnels."b8627eb8-2dfc-4ec8-9c5f-f59c3c2d1d1e" = {
				# TODO: replace with your tunnel UUID (cloudflared tunnel create miniflux)
				credentialsFile = "/var/lib/cloudflared/miniflux.json";
				default = "http_status:404";
				ingress = {
					"feed.cqjro.ca" = "http://localhost:8084";
				};
			};
		};
	};
}