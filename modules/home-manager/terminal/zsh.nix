{ ... }:
{
	flake.modules.nixos.zsh = {
		programs.zsh.enable = true;
	};

	flake.modules.homeManager."zsh" = { pkgs, ... }: {
		home.packages = with pkgs; [
			zsh
		];

		programs.zsh = {
			enable = true;
			enableCompletion = true;
			autosuggestion.enable = true;
			syntaxHighlighting.enable = true;

			envExtra = ''
				if [ -f "$HOME/.config/nix/nix.conf" ]; then
					export NIX_CONFIG="$(cat "$HOME/.config/nix/nix.conf")"
				fi
			'';

			shellAliases = {
				ll = "eza -l --header";
				llt = "eza -l --tree --header";
				cd = "z";
				rebuild = "bash ${../../../rebuild.sh}";
				config-sync = "bash ${../../scripts/config-sync.sh}";
				xremap-binds = "bash ${../../scripts/keybind-cheatsheet.sh} ${../keyboard/xremap.nix} ${../../scripts/parse_xremap.py}";
			};

			# No tty1 autostart of Hyprland here: sessions are chosen in the
			# noctalia greeter. greetd runs every session through this login
			# shell on tty1 with DISPLAY unset, so the old
			# `exec start-hyprland` check turned every other session (Plasma
			# Bigscreen, Plasma) into Hyprland. From a bare tty, run
			# `start-hyprland` by hand.
		};
	};
}