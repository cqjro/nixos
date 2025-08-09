{pkgs, inputs, ...}:
{
	imports = [
		./hyprland.nix
		./gtk.nix
		./waybar.nix
		./dunst.nix
		./xdg-desktop-entries.nix
		./rofi.nix
	];

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
		inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default #cursor theme

		# utils
		networkmanagerapplet
		blueman
		playerctl
		brightnessctl
		bluez
	];
}
