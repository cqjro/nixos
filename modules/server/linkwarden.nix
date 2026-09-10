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
			enableRegistration = false;

			environment = {
				NEXT_PUBLIC_URL = "https://link.cqjro.ca";
				NEXTAUTH_URL = "https://link.cqjro.ca";
			};
		};

		services.cloudflared = {
			tunnels."251c3fc1-0571-40a0-9b99-aefa81d37838" = {
				credentialsFile = "/var/lib/cloudflared/linkwarden.json";
				default = "http_status:404";
				ingress = {
					"link.cqjro.ca" = "http://localhost:8083";
				};
			};
		};
	};
}
