{ inputs, ... }:
{
	flake.modules.homeManager."discord" = {
		imports = [
			inputs.nixcord.homeModules.nixcord
			inputs.self.modules.homeManager.discord-theme
		];

		programs.nixcord = {
			enable = true;
			discord.enable = true;
			# Discord runs unmodded on purpose; Vesktop is the modded client.
			discord.silenceNoModClientWarning = true;
			vesktop = {
				enable = true;
				settings = {
					discordBranch = "canary";
					staticTitle = false;
					splashTheming = true;
					# splashColor = "rgb(186, 194, 222)";
					# splashBackground = "rgb(30, 30, 46)";
					arRPC = false;
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
		};
	};
}