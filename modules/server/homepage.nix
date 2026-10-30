{ ... }:
{
	flake.modules.nixos.homepage = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			homepage-dashboard
		];

		services.homepage-dashboard = {
			enable = true;
			listenPort = 8082; # default

			settings = {
				title = "REDRUM";
			};
			# "Homelab" tab: one entry per REDRUM app exposed via a cloudflared
			# tunnel (kept in sync with the modules in this directory).
			services = [
				{
					Homelab = [
						{
							"Glance" = {
								href = "https://home.cqjro.ca";
								description = "Dashboard";
								abbr = "GL";
							};
						}
						{
							"Paperless" = {
								href = "https://docs.cqjro.ca";
								description = "Documents";
								abbr = "PL";
							};
						}
						{
							"Beszel" = {
								href = "https://status.cqjro.ca";
								description = "Server monitoring";
								abbr = "BZ";
							};
						}
						{
							"Linkwarden" = {
								href = "https://link.cqjro.ca";
								description = "Bookmarks";
								icon = "linkwarden";
							};
						}
						{
							"Actual Budget" = {
								href = "https://budget.cqjro.ca";
								description = "Budgeting";
								icon = "actualbudget";
							};
						}
						{
							"Miniflux" = {
								href = "https://feed.cqjro.ca";
								description = "RSS reader";
								icon = "miniflux";
							};
						}
						{
							"ReactFlux" = {
								href = "https://flux.cqjro.ca";
								description = "Miniflux client";
								abbr = "RF";
							};
						}
					];
				}
			];
		};
	};
}
