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
}
