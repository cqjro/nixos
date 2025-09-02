{pkgs, inputs, ...}:
{
	imports = [
		./discord/nixcord.nix
		./zen-browser.nix
		./nemo.nix
	];

	home.packages = with pkgs; [
		vlc
		mpv
		obsidian
		spotify
		obs-studio
		firefox # backup browser
		protonmail-desktop # email
		protonvpn-cli # vpn cli
		protonvpn-gui # vpn gui
		proton-pass # password managerd a desire for self-hosted deployments to their hardware/corporate cloud environments for added data security and controls. 
		zathura # pdf viewer
		sioyek # pdf viewer for academic documents
		localsend # airdrop replacement	
		remmina # remote desktop on linux
		newsflash # RSS reader/news app
		onlyoffice-desktopeditors # microsoft suite replacement
		xfce.ristretto # image viewer
		vimiv-qt # image viewer
		gthumb # Image viewer/editor
		shotwell # Image viewer/editor
	];
}
