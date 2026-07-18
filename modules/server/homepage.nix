{pkgs, ...}:
{
	environment.systemPackages = with pkgs; [
		homepage-dashboard
	];

	services.homepage-dashboard = {
		enable = true;
		listenPort = 8082; # default

		settings = {
			title = "REDRUM";
		};

		services = [
			# insert services here?
		];

	};

}
