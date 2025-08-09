{ pkgs, ... }:

{
	# Home Manager needs a bit of information about you and the paths it should
	# manage.
	home.username = "cairo";
	home.homeDirectory = "/home/cairo";

	# This value determines the Home Manager release that your configuration is
	# compatible with. This helps avoid breakage when a new Home Manager release
	# introduces backwards incompatible changes.
	#
	# You should not change this value, even if you update Home Manager. If you do
	# want to update the value, then make sure to first check the Home Manager
	# release notes.
	home.stateVersion = "24.11"; # Please read the comment before changing.

	#TODO group these togeher with default import files like in example configs
	imports = [
		../../modules/keyboard/default.nix
		../../modules/desktop/default.nix
		../../modules/terminal/default.nix
		../../modules/apps/default.nix
	];

	home.sessionVariables = {
		EDITOR = "nvim";
		BROWSER = "zen";
		TERMINAL = "ghostty";
		NIXOS_OZONE_WL = "1";
		ELECTRON_OZONE_PLATFORM_HINT = "wayland";
		OZONE_PLATFORM_HINT = "wayland";
		XDG_SESSION_TYPE = "wayland";
		XDG_SESSION_DESKTOP = "Hyprland";
	};

	# get rid of mismatch version error on rebuild	
	stylix.enableReleaseChecks = false;

	hyprland = {
		enable = true;
		monitors = [
			"eDP-1,2560x1600@60,0x0,1.25"
		];
	};


	home.file = {};

	home.sessionPath = [ 
		"/homes/cairo/.nixos"
	];

	# Let Home Manager install and manage itself.
	programs.home-manager.enable = true;
}
