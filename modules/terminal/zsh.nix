{pkgs, lib, config, inputs, ...}:
{
	programs.zsh = {
		enable = true;
		enableCompletion = true;
		autosuggestion.enable = true;
		syntaxHighlighting.enable = true;

		shellAliases = {
			ll = "eza -l --header";
			llt = "eza -l --tree --header";
			cd = "z";
			rebuild = "bash ~/.nixos/rebuild.sh";
		};

		profileExtra = ''
			if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
  			exec Hyprland
			fi
		'';
	};
}
