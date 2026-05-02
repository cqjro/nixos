{pkgs, inputs, ...}:
{
	imports = [
		./discord/nixcord.nix
		./zen-browser.nix
		./nemo.nix
	];

	home.packages = with pkgs; [
		# media viewers
		vlc
		mpv
		spotify
		zathura # pdf viewer
		sioyek # pdf viewer for academic documents

		# image viewers (TODO delete like all of these when settled on one in particular)
		ristretto # image viewer
		vimiv-qt # image viewer
		gthumb # Image viewer/editor
		shotwell # Image viewer/editor

		# productivity & utilities
		obsidian
		protonmail-desktop # email
		proton-vpn-cli # vpn cli
		proton-vpn # vpn gui
		proton-pass # password manager
		obs-studio
		localsend # airdrop replacement
		remmina # remote desktop on linux
		onlyoffice-desktopeditors # microsoft suite replacement

		# browsers
		inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
		firefox
		brave
		ungoogled-chromium

		# other
		newsflash # RSS reader/news app
	];
}
