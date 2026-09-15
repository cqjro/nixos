{ ... }:
{
	flake.modules.nixos.glance = { pkgs, lib, ... }:
	{
		# Dedicated user, mirroring the linkwarden/actual-budget modules. The
		# nixpkgs module uses DynamicUser=true by default; we pin it to a stable
		# user so the admin (and `sudo -u`) can manage /var/lib/glance and the
		# generated config is chowned to the same user (see the unit override).
		users.users.glance = {
			isSystemUser = true;
			group = "glance";
			home = "/var/lib/glance";
			createHome = true;
		};
		users.groups.glance = {};

		# When the stylix module is also enabled on the host,
		# services.glance.settings.theme is filled in from the base16 palette
		# (stylix target: glance).
		services.glance = {
			enable = true;
			# Values referenced as ${VAR} in settings (e.g. the auth password)
			# are read from this file at runtime, keeping secrets out of the
			# nix store. Lives outside the store, see the file permissions
			# steps in the README.
			environmentFile = "/var/lib/glance/glance.env";
			settings = {
				server = {
					host = "127.0.0.1"; # only reachable via cloudflared tunnel
					port = 8081; # free port, avoids homepage 8082 / linkwarden 8083
					proxied = true; # trust X-Forwarded-* from cloudflared for the login brute-force block
				};

				# Restrict dashboard access behind username/password login.
				auth = {
					users = [
						{ username = "admin"; password = "\${GLANCE_PASSWORD}"; }
					];
				};

				pages = [
					{
						name = "Home";
						columns = [
							{
								size = "full";
								widgets = [
									{
										type = "clock";
										timezones = [
											{
												timezone = "America/Toronto";
												label = "REDRUM";
											}
										];
									}
								];
							}
							{
								size = "full";
								widgets = [
									{
										# v0.8: `group` tabs OTHER widgets — the widget for a
										# list of links is `bookmarks` (groups -> links).
										type = "bookmarks";
										groups = [
											{
												title = "Services";
												links = [
													{ title = "Paperless"; url = "https://docs.cqjro.ca"; }
													{ title = "Beszel"; url = "https://status.cqjro.ca"; }
													{ title = "Linkwarden"; url = "https://link.cqjro.ca"; }
													{ title = "Actual Budget"; url = "https://budget.cqjro.ca"; }
													{ title = "NixOS Config"; url = "https://github.com/cqjro/nixos"; }
												];
											}
										];
									}
								];
							}
						];
					}
				];
			};
		};

		# Pin glance to its dedicated user instead of a dynamic user.
		# `StateDirectory = glance` (/var/lib/glance) then gets chowned to
		# `glance` on unit start, and the ExecStartPre chown keeps the generated
		# config in line with the same user.
		systemd.services.glance.serviceConfig = {
			DynamicUser = lib.mkForce false;
			User = "glance";
			Group = "glance";
		};

		services.cloudflared = {
			tunnels."cc6ff7b2-85db-4d20-a99d-8ac3d05d14f7" = {
				# TODO: replace with your tunnel UUID (cloudflared tunnel create glance)
				credentialsFile = "/var/lib/cloudflared/glance.json";
				default = "http_status:404";
				ingress = {
					"home.cqjro.ca" = "http://localhost:8081";
				};
			};
		};
	};
}
