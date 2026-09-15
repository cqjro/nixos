{ ... }:
{
	flake.modules.nixos.paperless = { pkgs, ... }:
	let
		appUser = "paperless";
		workDir = "/var/lib/paperless";
	in
	{
		# Dedicated user, mirroring the linkwarden/actual-budget modules. The
		# nixpkgs paperless module additionally allocates fixed uid/gid and adds
		# the redis group membership when the default user is kept.
		users.users.${appUser} = {
			isSystemUser = true;
			group = appUser;
			home = workDir;
			createHome = true;
		};
		users.groups.${appUser} = {};

		services.paperless = {
			enable = true;
			user = appUser;
			group = appUser;
			address = "127.0.0.1"; # only reachable via cloudflared tunnel
			port = 8091; # free port, avoids homepage 8082 / linkwarden 8083
			dataDir = workDir;

			# A superuser is created automatically after this file exists
			# (default username `admin`). Lives outside the nix store, see
			# the cloudflared setup steps below.
			passwordFile = "${workDir}/admin-password";

			settings = {
				PAPERLESS_URL = "https://docs.cqjro.ca";
				PAPERLESS_OCR_LANGUAGE = "eng";
			};

			# Postgres runs locally on REDRUM (redis is auto-configured).
			# Flip `configureTika = true` for OCR of Office/e-mail files
			# (pull in gotenberg + tika JVM services).
			database.createLocally = true;
		};

		services.cloudflared = {
			tunnels."76e5273f-8ce6-44e6-b812-45b443351248" = {
				credentialsFile = "/var/lib/cloudflared/paperless.json";
				default = "http_status:404";
				ingress = {
					"docs.cqjro.ca" = "http://localhost:8091";
				};
			};
		};
	};
}
