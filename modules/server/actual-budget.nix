{ ... }:
let
	appUser = "actual";
	workDir = "/var/lib/actual";
in
{
	flake.modules.nixos.actual-budget = { pkgs, ... }: {
		users.users.${appUser} = {
			isSystemUser = true;
			group = appUser;
			home = workDir;
			createHome = true;
		};
		users.groups.${appUser} = {};

		services.actual = {
			enable = true;
			user = appUser;
			group = appUser;
			openFirewall = true;
			settings = {
				port = 5006; # default
				dataDir = workDir;
			};
		};

		services.cloudflared = {
			tunnels."ad444bc6-e186-49a2-ac8d-7a9f1bba6617" = {
				credentialsFile = "/var/lib/cloudflared/actual-budget.json";
				default = "http_status:404";
				ingress = {
					"budget.cqjro.ca" = "http://localhost:5006";
				};
			};
		};
	};
}