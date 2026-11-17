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
		# "Make Model Serial" exactly as `niri msg outputs` prints them (checked
		# on THEOCIDE 2026-11-17). niri takes the refresh rate from the mode list,
		# so the OLED's is 164.992, not 165.000.
		niri = {
			outputs = {
				"PNP(BNQ) BenQ EW2780U L6L01871019" = {
					mode = "3840x2160@59.997";
					scale = 1.5;
					position = { x = 640; y = -1440; };
				};
				"Microstep MAG321UP OLED Unknown" = {
					mode = "3840x2160@164.992";
					scale = 1.0;
					position = { x = 0; y = 0; };
				};
			};
			# Blur off under niri: with niri's compositor blur on, windows in the
			# OLED's right-hand column flickered black/purple at 164.992 Hz (fine at
			# 120 Hz, with blur off, and in Hyprland, which keeps its own blur). Not the
			# cursor plane, not frame completion. Retry after a niri or driver bump.
			blur = false;
		};
	};
}