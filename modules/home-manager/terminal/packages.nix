{ ... }:
{
	flake.modules.homeManager."terminal-packages" = { pkgs, ... }: {
		home.packages = with pkgs; [
			nitch # neofetch replacement
			ffmpeg # video handling
			fzf # fuzzy text search
			eza # better ls
			dust # disk usage analyzer
			dua # interactive disk use analyzer
			jq # json command line processor
			unzip # unzipping zip files from terminal
			youtube-tui
			# nom # terminal rss reader (see modules/home-manager/terminal/nom.nix)
			# age # secrets/encryption manager
			bluetui # bluetooh manager tui
			ncdu # storage manager
			wiremix # audio picker
			_7zz # 7zip terminal utility
			aider-chat # ai chat bot for coding
		];
	};
}