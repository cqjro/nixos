{pkgs, ...}:
{
	imports = [
		./bat.nix
		./btop.nix
		./ghostty.nix
		./git.nix
		./ncspot.nix
		./nvim/neovim.nix
		./starship.nix
		./yazi.nix
		./zoxide.nix
		./zsh.nix
	];

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
		nom # terminal rss reader
		# age # secrets/encryption manager
	];

}
