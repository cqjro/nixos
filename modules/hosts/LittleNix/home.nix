{ ... }:
{
	flake.modules.homeManager.LittleNix = {
		home.username = "cairo";
		home.homeDirectory = "/home/cairo";

		# This value determines the Home Manager release that your configuration is
		# compatible with. This helps avoid breakage when a new Home Manager release
		# introduces backwards incompatible changes.
		home.stateVersion = "24.11";

		home.file = {};

		# Let Home Manager install and manage itself.
		programs.home-manager.enable = true;

		# get rid of mismatch version error on rebuild
		stylix.enableReleaseChecks = false;

		hyprland = {
			monitors = [
				"eDP-1,2560x1600@60,0x0,1.25"
			];
		};
	};
}