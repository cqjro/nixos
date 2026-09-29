{ inputs, ... }:
{
	flake.modules.homeManager."discord" = {
		imports = [
			inputs.nixcord.homeModules.nixcord
			inputs.self.modules.homeManager.discord-theme
		];

		programs.nixcord = {
			enable = true;
			# TODO-remove: Discord package install is disabled pending an upstream
			# nixcord fix. nixcord's `pkgs/discord/default.nix` unconditionally does
			# `basePackage.override { inherit source; ... }`, but nixpkgs refactored
			# `discord` into `pkgs/by-name/di/discord/package.nix` where `source` is
			# derived from `./metadata.nix` and is no longer a function argument.
			# Because `nixcord.inputs.nixpkgs.follows = "nixpkgs"` (flake.nix), any
			# nixpkgs bump breaks evaluation with:
			#   error: function 'anonymous lambda' called with unexpected argument 'source'
			# Vesktop is a separate package and keeps working, so only the standalone
			# `discord` binary is given up: Vencord, the Stylix `quickCss` theme,
			# `config.plugins` and the Vesktop settings are all still applied.
			# Re-enable (set to true) once nixcord guards `source` the same way it
			# guards `useFHSEnv` (`basePackageSupportsFHSEnv`). See AGENTS.md
			# "Pending upstream fixes" and README.md "Pending upstream fixes".
			discord.enable = false;
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