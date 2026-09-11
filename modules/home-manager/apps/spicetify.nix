{ inputs, ... }:
{
	flake.modules.homeManager."spicetify" = { osConfig, lib, pkgs, config, ... }: {
		imports = [ inputs.spicetify-nix.homeManagerModules.default ];

		# switch between the spicetify-patched client and a vanilla spotify client
		programs.spicetify = lib.mkIf osConfig.manifest.enableSpicetify {
			enable = true;
			wayland = true; # native wayland instead of xwayland

			# discord-inspired colour mapping, see modules/home-manager/apps/discord/theme.nix:
			# flat base00 background, base01/base02 elevation, base03 borders & hover,
			# base05/base04 text, base0D brand accent, base0B success, base08 danger.
			theme = {
				name = "stylix";
				src = pkgs.writeTextFile {
					name = "color.ini";
					destination = "/color.ini";
					text = lib.generators.toINI { } {
						base = with config.lib.stylix.colors; {
							text = base05;
							subtext = base04;
							main = base00;
							main-elevated = base01;
							highlight = base02;
							highlight-elevated = base03;
							sidebar = base00;
							player = base00;
							card = base02;
							shadow = base00;
							selected-row = base05;
							button = base0D;
							button-active = base05;
							button-disabled = base03;
							tab-active = base0D;
							notification = base02;
							notification-error = base08;
							equalizer = base0B;
							misc = base02;
						};
					};
				};
				# sidebar configuration is incompatible with the navigation bar
				sidebarConfig = false;
			};
			colorScheme = "base";
		};

		# we manage the colour mapping ourselves (above)
		stylix.targets.spicetify.enable = false;

		home.packages = lib.mkIf (!osConfig.manifest.enableSpicetify) [
			pkgs.spotify
		];
	};
}