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
			bindel = [
				",XF85MonBrightnessUp, exec, brightnessctl --device acpi_video0 -e4 -n2 set 5%+"
				",XF85MonBrightnessDown, exec, brightnessctl --device acpi_video0 -e4 -n2 set 5%-"
				",XF85KbdBrightnessUp, exec, brightnessctl --device :white:kbd_backlight -e4 set 5%+"
				",XF85KbdBrightnessDown, exec, brightnessctl --device :white:kbd_backlight -e4 set 5%-"
			];
		};

		home.sessionPath = [
			"/homes/cairo/.nixos"
		];
	};
}