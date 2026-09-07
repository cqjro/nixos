{ inputs, ... }:
let
  rosePineHyprcursor = inputs.rose-pine-hyprcursor.packages.x86_64-linux.default;
in
{
	flake.modules.homeManager."desktop-packages" = { pkgs, ... }: {
		home.packages = with pkgs; [
			# desktop basics
			hypridle
			hyprlock

			# Config Dependencies
			ags
			grim
			slurp
			wl-clipboard
			wl-clip-persist
			upower
			power-profiles-daemon
			grimblast # screen shots
			hyprpicker # colour picker
			hyprcursor # better cursors
			rosePineHyprcursor # cursor theme

			# utils
			networkmanagerapplet
			blueman
			playerctl
			brightnessctl
			bluez
			pavucontrol
			pwvucontrol
			libnotify
		];
	};
}