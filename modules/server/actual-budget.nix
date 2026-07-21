{ pkgs, ... }:
{
	environment.systemPackages = with pkgs; [
		actual-server
	];

	services.actual = {
		enable = true;
		openFirewall = true;
		settings = {
			port = 5006; #default
			# hostname = "0.0.0.0";
		};
	};

	services.cloudflared = {
		tunnels."ad444bc6-e186-49a2-ac8d-7a9f1bba6617" = {
			credentialsFile = "/var/lib/cloudflared/actual-budget.json";
			default = "http_status:404";
			ingress = {
				"budget.cqjro.ca" = "https://localhost:5006";
			};

		};
	};
}
