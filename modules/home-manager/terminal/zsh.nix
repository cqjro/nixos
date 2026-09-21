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

			shellAliases = {
				ll = "eza -l --header";
				llt = "eza -l --tree --header";
				cd = "z";
				rebuild = "bash ${../../../rebuild.sh}";
				xremap-binds = "bash ${../../scripts/keybind-cheatsheet.sh} ${../keyboard/xremap.nix} ${../../scripts/parse_xremap.py}";
			};

			profileExtra = ''
				if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
  					exec start-hyprland
				fi
			'';
		};
	};
}