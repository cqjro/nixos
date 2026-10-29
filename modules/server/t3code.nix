{ ... }:
let
	appUser = "t3code";
	workDir = "/var/lib/t3code";
in
{
	flake.modules.nixos.t3code = { pkgs, lib, ... }: {
		users.users.${appUser} = {
			isSystemUser = true;
			group = appUser;
			home = workDir;
			createHome = true;
		};
		users.groups.${appUser} = {};

		systemd.services.t3code = {
			description = "T3 Code server";
			after = [ "network.target" ];
			wantedBy = [ "multi-user.target" ];

			serviceConfig = {
				Type = "simple";
				User = appUser;
				Group = appUser;
				WorkingDirectory = workDir;
				Environment = [
					"HOME=${workDir}"
					"XDG_DATA_HOME=${workDir}/.local/share"
					"XDG_CONFIG_HOME=${workDir}/.config"
				];
				ExecStart = "${pkgs.t3code}/bin/t3 serve --host 127.0.0.1 --port 8086";
				Restart = "on-failure";
				RestartSec = 5;
			};
		};

		services.cloudflared = {
			tunnels."TODO-REPLACE-WITH-T3CODE-TUNNEL-UUID" = {
				# TODO: replace with your tunnel UUID (cloudflared tunnel create t3code)
				credentialsFile = "/var/lib/cloudflared/t3code.json";
				default = "http_status:404";
				ingress = {
					"t3.cqjro.ca" = "http://localhost:8086";
				};
			};
		};
	};
}
