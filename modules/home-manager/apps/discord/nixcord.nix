{pkgs, lib, config, inputs, ...}:
let
	theme = import ./discord-theme.nix {
		inherit (config.lib.stylix) colors;
		inherit (config.stylix) fonts;
	};
in	
	{
	imports = [
		inputs.nixcord.homeModules.nixcord
	];

	stylix.targets.nixcord.enable = false;

	programs.nixcord = {
		enable = true;
		discord.enable = false;
		vesktop = {
			enable = true;
			settings = {
				# discordBranch = "canary";
				staticTitle = false;
				splashTheming = true;
				splashColor = "rgb(186, 194, 222)";
				splashBackground = "rgb(30, 30, 46)";
				# arRPC = false;
				minimizeToTray = false;
  			tray = false;	
			};
		};
		
		config = {
			useQuickCss = true;
			# frameless = true;
			plugins = {
				youtubeAdblock.enable = true;
			};
		};

		quickCss = theme; 

	};
}
