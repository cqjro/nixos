{ ... }:
let
	appUser = "linkwarden";
	workDir = "/var/lib/linkwarden";
in
{
	flake.modules.nixos.linkwarden = { pkgs, ... }: {
		users.users.${appUser} = {
			isSystemUser = true;
			group = appUser;
			home = workDir;
			createHome = true;
		};
		users.groups.${appUser} = {};

		services.linkwarden = {
			enable = true;
			host = "127.0.0.1"; # only reachable via cloudflared tunnel
			port = 8083; # free port, homepage uses 8082
			storageLocation = workDir;

			# secrets live outside the nix store (see README steps on setup)
			secretFiles = {
				NEXTAUTH_SECRET = "${workDir}/nextauth-secret";
				POSTGRES_PASSWORD = "${workDir}/postgres-password";
			};

			# allow creating the first account, flip to false after registering
			enableRegistration = true;

			environment = {
				NEXT_PUBLIC_URL = "https://link.cqjro.ca";
			};
		};

		services.cloudflared = {
			tunnels."REPLACE_WITH_LINKWARDEN_TUNNEL_UUID" = {
				credentialsFile = "/var/lib/cloudflared/linkwarden.json";
				default = "http_status:404";
				ingress = {
					"link.cqjro.ca" = "http://localhost:8083";
				};
			};
		};
	};
}