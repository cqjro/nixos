{pkgs, ...}:
{
	imports = [
		./discord/nixcord.nix
		./zen-browser.nix
		./nemo.nix
	];

	home.packages = with pkgs; [
		vlc
    obsidian
    spotify
    obs-studio
		firefox # backup browser
		protonmail-desktop # email
		protonvpn-cli # vpn cli
		protonvpn-gui # vpn gui
    zathura # pdf viewer
		sioyek # pdf viewer for academic documents
		localsend # airdrop replacement	
		remmina # remote desktop on linux
	];
}
