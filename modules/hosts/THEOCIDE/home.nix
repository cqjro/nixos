{ ... }:
{
	flake.modules.homeManager.THEOCIDE = {
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

		# configuring pc specific hyprland settings
		hyprland = {
			monitors = [
				"desc:BNQ BenQ EW2780U L6L01871019,3840x2160@60,640x-1440,1.50" # BENQ
				"desc:Microstep MAG321UP OLED,3840x2160@165,0x0,1.00" # MSI OLED
			];
		};

		# the same two monitors for the niri backup session. Names are niri's
		# "Make Model Serial" (see `niri msg outputs`); the OLED's serial is not
		# known here, so check it on first use and fix the key if niri ignores it.
		niri = {
			outputs = {
				"BNQ BenQ EW2780U L6L01871019" = {
					mode = "3840x2160@60.000";
					scale = 1.5;
					position = { x = 640; y = -1440; };
				};
				"Microstep MAG321UP OLED Unknown" = {
					mode = "3840x2160@165.000";
					scale = 1.0;
					position = { x = 0; y = 0; };
				};
			};
			blur = true; # same as Hyprland's decoration.blur
		};
	};
}